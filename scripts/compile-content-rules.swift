#!/usr/bin/env swift
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

private struct ContentRule: Encodable {
    struct Trigger: Encodable {
        let urlFilter: String
        let resourceType: [String]?
        let loadType: [String]?
        let ifDomain: [String]?
        let unlessDomain: [String]?

        enum CodingKeys: String, CodingKey {
            case urlFilter = "url-filter"
            case resourceType = "resource-type"
            case loadType = "load-type"
            case ifDomain = "if-domain"
            case unlessDomain = "unless-domain"
        }
    }

    struct Action: Encodable {
        let type: String
    }

    let trigger: Trigger
    let action: Action
}

private struct Manifest: Encodable {
    struct Source: Encodable {
        let name: String
        let version: String
        let commit: String
        let lastModified: String
        let sourceFile: String
    }

    struct Shard: Encodable {
        let identifier: String
        let file: String
        let ruleCount: Int
    }

    let formatVersion: Int
    let sources: [Source]
    let shards: [Shard]
    let totalRuleCount: Int
}

private struct ConvertedList {
    let source: Manifest.Source
    let blockingRules: [ContentRule]
    let exceptionRules: [ContentRule]
}

private let supportedResourceTypes: [String: String] = [
    "document": "document",
    "font": "font",
    "image": "image",
    "media": "media",
    "object": "raw",
    "other": "raw",
    "ping": "raw",
    "popup": "popup",
    "script": "script",
    "stylesheet": "style-sheet",
    "subdocument": "document",
    "websocket": "raw",
    "xmlhttprequest": "raw",
]

private let allResourceTypes = Set(supportedResourceTypes.values)
private let unsupportedOptions = [
    "csp",
    "denyallow",
    "header",
    "method",
    "permissions",
    "redirect",
    "redirect-rule",
    "removeparam",
    "replace",
    "urltransform",
]

private func headerValue(_ key: String, lines: [Substring]) -> String {
    let prefix = "! \(key):"
    guard let line = lines.first(where: { $0.hasPrefix(prefix) }) else {
        return "unknown"
    }
    return line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
}

private func regexEscaped(_ character: Character) -> String {
    "\\.^$+?()[]{}|".contains(character) ? "\\\(character)" : String(character)
}

private func convertPattern(_ rawPattern: String) -> String? {
    guard !rawPattern.isEmpty,
          rawPattern.utf8.count <= 2_000,
          rawPattern.unicodeScalars.allSatisfy(\.isASCII),
          !(rawPattern.hasPrefix("/") && rawPattern.hasSuffix("/")) else {
        return nil
    }

    var pattern = rawPattern.lowercased()
    var prefix = ""
    var suffix = ""

    if pattern.hasPrefix("||") {
        pattern.removeFirst(2)
        prefix = "^[a-z][a-z0-9+.-]*://([^/]+\\.)?"
    } else if pattern.hasPrefix("|") {
        pattern.removeFirst()
        prefix = "^"
    }

    if pattern.hasSuffix("|") {
        pattern.removeLast()
        suffix = "$"
    }

    var output = ""
    for character in pattern {
        switch character {
        case "*":
            output += ".*"
        case "^":
            output += "[^a-z0-9_\\-.%]"
        default:
            output += regexEscaped(character)
        }
    }

    guard !output.isEmpty else {
        return nil
    }
    return prefix + output + suffix
}

private func normalizedDomains(_ value: String) -> (included: [String], excluded: [String]) {
    var included: [String] = []
    var excluded: [String] = []

    for rawDomain in value.split(separator: "|").map(String.init) {
        let isExcluded = rawDomain.hasPrefix("~")
        let domain = isExcluded ? String(rawDomain.dropFirst()) : rawDomain
        guard !domain.isEmpty else {
            continue
        }
        let normalized = domain.hasPrefix("*") ? domain : "*\(domain)"
        if isExcluded {
            excluded.append(normalized)
        } else {
            included.append(normalized)
        }
    }
    return (included, excluded)
}

private func convertLine(_ rawLine: Substring) -> (ContentRule, Bool)? {
    var line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !line.isEmpty,
          !line.hasPrefix("!"),
          !line.hasPrefix("["),
          !line.contains("##"),
          !line.contains("#@#"),
          !line.contains("#?#"),
          !line.contains("#$#"),
          !line.contains("#%#") else {
        return nil
    }

    let isException = line.hasPrefix("@@")
    if isException {
        line.removeFirst(2)
    }

    let components = line.split(separator: "$", maxSplits: 1, omittingEmptySubsequences: false)
    let rawPattern = String(components[0])
    let options = components.count == 2
        ? components[1].split(separator: ",").map(String.init)
        : []

    guard !options.contains(where: { option in
        let name = option.split(separator: "=", maxSplits: 1).first.map(String.init) ?? option
        return unsupportedOptions.contains(name.trimmingPrefix("~"))
    }), let urlFilter = convertPattern(rawPattern) else {
        return nil
    }

    var includedTypes = Set<String>()
    var excludedTypes = Set<String>()
    var loadType: [String]?
    var includedDomains: [String] = []
    var excludedDomains: [String] = []

    for option in options {
        let isNegated = option.hasPrefix("~")
        let normalizedOption = isNegated ? String(option.dropFirst()) : option
        let pair = normalizedOption.split(separator: "=", maxSplits: 1).map(String.init)
        let name = pair[0]

        if let resourceType = supportedResourceTypes[name] {
            if isNegated {
                excludedTypes.insert(resourceType)
            } else {
                includedTypes.insert(resourceType)
            }
        } else if name == "third-party" {
            loadType = [isNegated ? "first-party" : "third-party"]
        } else if name == "domain", pair.count == 2 {
            let domains = normalizedDomains(pair[1])
            includedDomains.append(contentsOf: domains.included)
            excludedDomains.append(contentsOf: domains.excluded)
        }
    }

    let resourceTypes: [String]?
    if !includedTypes.isEmpty {
        resourceTypes = Array(includedTypes.subtracting(excludedTypes)).sorted()
    } else if !excludedTypes.isEmpty {
        resourceTypes = Array(allResourceTypes.subtracting(excludedTypes)).sorted()
    } else {
        resourceTypes = nil
    }

    guard resourceTypes?.isEmpty != true else {
        return nil
    }

    let rule = ContentRule(
        trigger: .init(
            urlFilter: urlFilter,
            resourceType: resourceTypes,
            loadType: loadType,
            ifDomain: includedDomains.isEmpty ? nil : includedDomains.sorted(),
            unlessDomain: excludedDomains.isEmpty ? nil : excludedDomains.sorted()
        ),
        action: .init(type: isException ? "ignore-previous-rules" : "block")
    )
    return (rule, isException)
}

private func convertList(at url: URL, name: String) throws -> ConvertedList {
    let text = try String(contentsOf: url, encoding: .utf8)
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    var blockingRules: [ContentRule] = []
    var exceptionRules: [ContentRule] = []

    for line in lines {
        guard let (rule, isException) = convertLine(line) else {
            continue
        }
        if isException {
            exceptionRules.append(rule)
        } else {
            blockingRules.append(rule)
        }
    }

    return ConvertedList(
        source: .init(
            name: name,
            version: headerValue("Version", lines: lines),
            commit: headerValue("Commit", lines: lines),
            lastModified: headerValue("Last modified", lines: lines),
            sourceFile: url.lastPathComponent
        ),
        blockingRules: blockingRules,
        exceptionRules: exceptionRules
    )
}

private extension String {
    func trimmingPrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
}

private func encodedJSON<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(value)
}

private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
    try encodedJSON(value).write(to: url, options: .atomic)
}

private func fingerprint(_ data: Data) -> String {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in data {
        hash ^= UInt64(byte)
        hash &*= 1_099_511_628_211
    }
    return String(hash, radix: 16)
}

private let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    FileHandle.standardError.write(
        Data("usage: compile-content-rules.swift EASYLIST EASYPRIVACY OUTPUT_DIR\n".utf8)
    )
    exit(64)
}

private let outputDirectory = URL(fileURLWithPath: arguments[3], isDirectory: true)
try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

private let convertedLists = try [
    convertList(at: URL(fileURLWithPath: arguments[1]), name: "EasyList"),
    convertList(at: URL(fileURLWithPath: arguments[2]), name: "EasyPrivacy"),
]

private let maximumRulesPerShard = 40_000
private var shards: [Manifest.Shard] = []

for convertedList in convertedLists {
    let baseName = convertedList.source.name.lowercased()
    let blockingRulesPerShard = maximumRulesPerShard - convertedList.exceptionRules.count

    for (index, offset) in stride(
        from: 0,
        to: convertedList.blockingRules.count,
        by: blockingRulesPerShard
    ).enumerated() {
        let blockingRules = convertedList.blockingRules[
            offset..<min(
                offset + blockingRulesPerShard,
                convertedList.blockingRules.count
            )
        ]
        let shardRules = Array(blockingRules) + convertedList.exceptionRules
        let fileName = "\(baseName)-\(index + 1).json"
        let encodedRules = try encodedJSON(shardRules)
        let identifier = "context-\(baseName)-\(index + 1)-\(fingerprint(encodedRules))"
        try encodedRules.write(
            to: outputDirectory.appendingPathComponent(fileName),
            options: .atomic
        )
        shards.append(.init(
            identifier: identifier,
            file: fileName,
            ruleCount: shardRules.count
        ))
    }
}

private let manifest = Manifest(
    formatVersion: 1,
    sources: convertedLists.map(\.source),
    shards: shards,
    totalRuleCount: shards.reduce(0) { $0 + $1.ruleCount }
)
try writeJSON(manifest, to: outputDirectory.appendingPathComponent("manifest.json"))

print("Generated \(manifest.totalRuleCount) rules in \(shards.count) shards.")
