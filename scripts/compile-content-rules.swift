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
        let selector: String?

        init(type: String, selector: String? = nil) {
            self.type = type
            self.selector = selector
        }
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
    let cosmeticRules: [ContentRule]
}

private struct CosmeticFilter {
    let selector: String
    let includedDomains: [String]
    let excludedDomains: [String]
    let isException: Bool
}

private struct CosmeticScriptScope: Hashable {
    let includedDomains: [String]
    let excludedDomains: [String]
}

private struct CosmeticScriptGroup: Encodable {
    let includedDomains: [String]
    let excludedDomains: [String]
    let selectors: [String]
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

private let supportedOptions = Set(supportedResourceTypes.keys).union([
    "domain",
    "third-party",
])

private let unsupportedCosmeticFragments = [
    ":-abp-",
    ":contains(",
    ":has-text(",
    ":matches-attr(",
    ":matches-css(",
    ":matches-property(",
    ":min-text-length(",
    ":nth-ancestor(",
    ":remove(",
    ":style(",
    ":upward(",
    ":watch-attr(",
    ":xpath(",
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

private func normalizedCosmeticDomains(
    _ value: String
) -> (included: [String], excluded: [String])? {
    guard !value.isEmpty else {
        return ([], [])
    }

    var included: [String] = []
    var excluded: [String] = []

    for rawValue in value.split(separator: ",", omittingEmptySubsequences: false) {
        var rawDomain = String(rawValue).trimmingCharacters(in: .whitespaces)
        let isExcluded = rawDomain.hasPrefix("~")
        if isExcluded {
            rawDomain.removeFirst()
        }

        let domain = rawDomain.lowercased()
        let wildcardCount = domain.filter { $0 == "*" }.count
        guard !domain.isEmpty,
              domain.utf8.count <= 253,
              domain.unicodeScalars.allSatisfy(\.isASCII),
              domain.allSatisfy({ character in
                  character.isLetter || character.isNumber || ".-*".contains(character)
              }),
              !domain.contains(".."),
              wildcardCount == 0 || (wildcardCount == 1 && domain.hasPrefix("*.")) else {
            return nil
        }

        let normalized = domain.hasPrefix("*") ? domain : "*\(domain)"
        if isExcluded {
            excluded.append(normalized)
        } else {
            included.append(normalized)
        }
    }

    return (
        Array(Set(included)).sorted(),
        Array(Set(excluded)).sorted()
    )
}

private func parseCosmeticLine(_ rawLine: Substring) -> CosmeticFilter? {
    let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !line.isEmpty,
          !line.hasPrefix("!"),
          !line.hasPrefix("["),
          !line.contains("#?#"),
          !line.contains("#@?#"),
          !line.contains("#$#"),
          !line.contains("#@$#"),
          !line.contains("#%#"),
          !line.contains("#@%#") else {
        return nil
    }

    let isException: Bool
    let marker: String
    if line.contains("#@#") {
        isException = true
        marker = "#@#"
    } else if line.contains("##") {
        isException = false
        marker = "##"
    } else {
        return nil
    }

    let components = line.components(separatedBy: marker)
    guard components.count == 2 else {
        return nil
    }

    let selector = components[1].trimmingCharacters(in: .whitespaces)
    let lowercasedSelector = selector.lowercased()
    guard !selector.isEmpty,
          selector.utf8.count <= 2_000,
          !selector.contains("\n"),
          !selector.contains("\r"),
          !selector.contains("\0"),
          !selector.contains("{"),
          !selector.contains("}"),
          !selector.hasPrefix("+js("),
          !selector.hasPrefix("^"),
          !unsupportedCosmeticFragments.contains(where: lowercasedSelector.contains),
          let domains = normalizedCosmeticDomains(components[0]) else {
        return nil
    }

    return CosmeticFilter(
        selector: selector,
        includedDomains: domains.included,
        excludedDomains: domains.excluded,
        isException: isException
    )
}

private func bareDomain(_ normalizedDomain: String) -> String {
    var domain = normalizedDomain
    while domain.hasPrefix("*") {
        domain.removeFirst()
    }
    if domain.hasPrefix(".") {
        domain.removeFirst()
    }
    return domain
}

private func domain(_ child: String, isWithin parent: String) -> Bool {
    let child = bareDomain(child)
    let parent = bareDomain(parent)
    return child == parent || child.hasSuffix(".\(parent)")
}

private func hardenedCosmeticSelector(_ selector: String) -> String {
    // Real sites frequently load utility styles after WebKit installs the
    // blocker stylesheet. Give element-hiding rules ID-level specificity so a
    // later `.flex` or `.block` rule cannot restore a matched advertisement.
    // Pseudo-elements cannot be nested inside :is(), so retain those filters.
    guard !selector.contains("::") else {
        return selector
    }
    return ":is(\(selector), #context-content-blocker-never-match)"
}

private func makeCosmeticRules(_ filters: [CosmeticFilter]) -> [ContentRule] {
    var globalExceptions = Set<String>()
    var exceptionDomainsBySelector: [String: Set<String>] = [:]

    for filter in filters where filter.isException {
        guard filter.excludedDomains.isEmpty else {
            continue
        }
        if filter.includedDomains.isEmpty {
            globalExceptions.insert(filter.selector)
        } else {
            exceptionDomainsBySelector[filter.selector, default: []]
                .formUnion(filter.includedDomains)
        }
    }

    var rules: [ContentRule] = []
    var seenRules = Set<String>()

    for filter in filters where !filter.isException {
        guard !globalExceptions.contains(filter.selector) else {
            continue
        }

        let exceptionDomains = exceptionDomainsBySelector[filter.selector] ?? []
        var includedDomains = filter.includedDomains
        var excludedDomains = Set(filter.excludedDomains)

        if includedDomains.isEmpty {
            excludedDomains.formUnion(exceptionDomains)
        } else {
            let allExclusions = excludedDomains.union(exceptionDomains)
            includedDomains.removeAll { includedDomain in
                allExclusions.contains { excludedDomain in
                    domain(excludedDomain, isWithin: includedDomain)
                        || domain(includedDomain, isWithin: excludedDomain)
                }
            }
            excludedDomains.removeAll()
            guard !includedDomains.isEmpty else {
                continue
            }
        }

        includedDomains = Array(Set(includedDomains)).sorted()
        let sortedExcludedDomains = Array(excludedDomains).sorted()
        let key = [
            filter.selector,
            includedDomains.joined(separator: ","),
            sortedExcludedDomains.joined(separator: ","),
        ].joined(separator: "\u{1F}")
        guard seenRules.insert(key).inserted else {
            continue
        }

        rules.append(ContentRule(
            trigger: .init(
                urlFilter: ".*",
                resourceType: nil,
                loadType: nil,
                ifDomain: includedDomains.isEmpty ? nil : includedDomains,
                unlessDomain: sortedExcludedDomains.isEmpty ? nil : sortedExcludedDomains
            ),
            action: .init(
                type: "css-display-none",
                selector: hardenedCosmeticSelector(filter.selector)
            )
        ))
    }

    return rules
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
        let normalizedName = name.trimmingPrefix("~")
        return unsupportedOptions.contains(normalizedName)
            || !supportedOptions.contains(normalizedName)
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
    var cosmeticFilters: [CosmeticFilter] = []

    for line in lines {
        if let cosmeticFilter = parseCosmeticLine(line) {
            cosmeticFilters.append(cosmeticFilter)
            continue
        }
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
        exceptionRules: exceptionRules,
        cosmeticRules: makeCosmeticRules(cosmeticFilters)
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

private func cosmeticEnforcementScript(
    for convertedLists: [ConvertedList]
) throws -> String {
    var selectorsByScope: [CosmeticScriptScope: Set<String>] = [:]

    for rule in convertedLists.flatMap(\.cosmeticRules) {
        guard let selector = rule.action.selector else {
            continue
        }
        let scope = CosmeticScriptScope(
            includedDomains: rule.trigger.ifDomain ?? [],
            excludedDomains: rule.trigger.unlessDomain ?? []
        )
        selectorsByScope[scope, default: []].insert(selector)
    }

    let groups = selectorsByScope.map { scope, selectors in
        CosmeticScriptGroup(
            includedDomains: scope.includedDomains,
            excludedDomains: scope.excludedDomains,
            selectors: selectors.sorted()
        )
    }.sorted { left, right in
        let leftKey = left.includedDomains.joined(separator: ",")
            + "|" + left.excludedDomains.joined(separator: ",")
        let rightKey = right.includedDomains.joined(separator: ",")
            + "|" + right.excludedDomains.joined(separator: ",")
        return leftKey < rightKey
    }
    let encodedGroups = try encodedJSON(groups)
    guard let groupsJSON = String(data: encodedGroups, encoding: .utf8) else {
        throw CocoaError(.fileWriteInapplicableStringEncoding)
    }

    return """
    // Runtime wrapper: Mozilla Public License 2.0.
    // Embedded EasyList and EasyPrivacy filter data: CC BY-SA 3.0 or later.
    // See third-party/easylist/NOTICE.md in Context's source distribution.
    // Generated by scripts/compile-content-rules.swift. Do not edit.
    (() => {
      if (globalThis.__contextCosmeticProtectionInstalled) return;
      globalThis.__contextCosmeticProtectionInstalled = true;

      const groups = \(groupsJSON);
      const host = location.hostname.toLowerCase().replace(/^\\.+|\\.+$/g, "");
      const domainMatches = pattern => {
        const domain = pattern.replace(/^\\*\\.?/, "");
        return host === domain || host.endsWith(`.${domain}`);
      };
      const applies = group =>
        (group.includedDomains.length === 0 || group.includedDomains.some(domainMatches)) &&
        !group.excludedDomains.some(domainMatches);
      const css = groups
        .filter(applies)
        .flatMap(group => group.selectors)
        .map(selector => `${selector} { display: none !important; }`)
        .join("\\n");
      if (!css) return;

      const styleID = "context-cosmetic-protection";
      let watchedRoot;
      const observer = new MutationObserver(() => {
        if (!document.getElementById(styleID)) install();
      });
      const install = () => {
        if (document.getElementById(styleID)) return;
        const root = document.head || document.documentElement;
        if (!root) return;
        const style = document.createElement("style");
        style.id = styleID;
        style.textContent = css;
        root.appendChild(style);
        if (watchedRoot !== root) {
          observer.disconnect();
          observer.observe(root, { childList: true });
          watchedRoot = root;
        }
      };
      install();
    })();
    """
}

private let arguments = CommandLine.arguments
if arguments.count == 2, arguments[1] == "--self-test" {
    precondition(convertLine("||ads.example^$elemhide") == nil)

    let scriptRule = convertLine("||tracker.example^$script")
    precondition(scriptRule?.0.action.type == "block")
    precondition(scriptRule?.0.trigger.resourceType == ["script"])

    let documentException = convertLine("@@||example.com^$document")
    precondition(documentException?.0.action.type == "ignore-previous-rules")
    precondition(documentException?.0.trigger.resourceType == ["document"])

    let genericCosmetic = parseCosmeticLine("##.advertisement")
    precondition(genericCosmetic?.selector == ".advertisement")
    precondition(genericCosmetic?.includedDomains.isEmpty == true)

    let yahooCosmetic = parseCosmeticLine(
        "yahoo.com##[data-content=\"Advertisement\"]"
    )
    let yahooRules = yahooCosmetic.map { makeCosmeticRules([$0]) }
    precondition(yahooRules?.count == 1)
    precondition(yahooRules?.first?.action.type == "css-display-none")
    precondition(
        yahooRules?.first?.action.selector
            == ":is([data-content=\"Advertisement\"], #context-content-blocker-never-match)"
    )
    precondition(yahooRules?.first?.trigger.ifDomain == ["*yahoo.com"])

    let cosmeticException = parseCosmeticLine("news.yahoo.com#@#.advertisement")
    let exceptionRules = [genericCosmetic, cosmeticException].compactMap { $0 }
    let protectedRules = makeCosmeticRules(exceptionRules)
    precondition(protectedRules.first?.trigger.unlessDomain == ["*news.yahoo.com"])

    precondition(parseCosmeticLine("example.com#?#div:has-text(Ad)") == nil)

    print("Content rule compiler self-test passed.")
    exit(0)
}

guard arguments.count == 5 else {
    FileHandle.standardError.write(
        Data(
            "usage: compile-content-rules.swift --self-test | EASYLIST EASYPRIVACY CONTEXT_LIST OUTPUT_DIR\n".utf8
        )
    )
    exit(64)
}

private let outputDirectory = URL(fileURLWithPath: arguments[4], isDirectory: true)
try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)
for artifactURL in try FileManager.default.contentsOfDirectory(
    at: outputDirectory,
    includingPropertiesForKeys: nil
) where artifactURL.pathExtension == "json" {
    try FileManager.default.removeItem(at: artifactURL)
}

private let convertedLists = try [
    convertList(at: URL(fileURLWithPath: arguments[1]), name: "EasyList"),
    convertList(at: URL(fileURLWithPath: arguments[2]), name: "EasyPrivacy"),
    convertList(at: URL(fileURLWithPath: arguments[3]), name: "Context"),
]

private let cosmeticScript = try cosmeticEnforcementScript(for: convertedLists)
try Data(cosmeticScript.utf8).write(
    to: outputDirectory.appendingPathComponent("cosmetic-enforcement.js"),
    options: .atomic
)

private let maximumRulesPerShard = 40_000
private var shards: [Manifest.Shard] = []

for convertedList in convertedLists {
    let baseName = convertedList.source.name.lowercased().replacingOccurrences(
        of: " ",
        with: "-"
    )
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
        let fileName = "\(baseName)-network-\(index + 1).json"
        let encodedRules = try encodedJSON(shardRules)
        let identifier = "context-\(baseName)-network-\(index + 1)-\(fingerprint(encodedRules))"
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

    for (index, offset) in stride(
        from: 0,
        to: convertedList.cosmeticRules.count,
        by: maximumRulesPerShard
    ).enumerated() {
        let shardRules = Array(convertedList.cosmeticRules[
            offset..<min(
                offset + maximumRulesPerShard,
                convertedList.cosmeticRules.count
            )
        ])
        let fileName = "\(baseName)-cosmetic-\(index + 1).json"
        let encodedRules = try encodedJSON(shardRules)
        let identifier = "context-\(baseName)-cosmetic-\(index + 1)-\(fingerprint(encodedRules))"
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
