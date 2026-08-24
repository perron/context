// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Combine
import Foundation
import WebKit

public struct ContentRuleManifest: Decodable, Sendable {
    public struct Source: Decodable, Sendable {
        public let name: String
        public let version: String
        public let commit: String
        public let lastModified: String
        public let sourceFile: String
    }

    public struct Shard: Decodable, Sendable {
        public let identifier: String
        public let file: String
        public let ruleCount: Int
    }

    public let formatVersion: Int
    public let sources: [Source]
    public let shards: [Shard]
    public let totalRuleCount: Int
}

@MainActor
public struct PreparedContentRules {
    public let manifest: ContentRuleManifest
    public let ruleLists: [WKContentRuleList]
    public let cosmeticEnforcementScript: WKUserScript
}

public enum ContentRuleBundleError: LocalizedError {
    case missingResource(String)
    case invalidText(String)
    case compilationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingResource(let resource):
            "Missing content rule resource: \(resource)"
        case .invalidText(let resource):
            "Content rule resource is not UTF-8: \(resource)"
        case .compilationFailed(let identifier):
            "WebKit could not compile content rules: \(identifier)"
        }
    }
}

@MainActor
public enum ContentRuleBundleLoader {
    public static func prepare(
        bundle: Bundle
    ) async throws -> PreparedContentRules {
        try await prepare(bundle: bundle, store: .default())
    }

    public static func prepare(
        bundle: Bundle,
        store: WKContentRuleListStore
    ) async throws -> PreparedContentRules {
        let manifestURL = try resourceURL(
            named: "manifest.json",
            bundle: bundle
        )
        let manifest = try JSONDecoder().decode(
            ContentRuleManifest.self,
            from: Data(contentsOf: manifestURL)
        )
        let cosmeticScriptSource = try textResource(
            named: "cosmetic-enforcement.js",
            bundle: bundle
        )
        var ruleLists: [WKContentRuleList] = []

        for shard in manifest.shards {
            if let existing = try? await lookup(
                identifier: shard.identifier,
                store: store
            ) {
                ruleLists.append(existing)
                continue
            }

            let encodedRules = try textResource(
                named: shard.file,
                bundle: bundle
            )
            let compiled: WKContentRuleList
            do {
                compiled = try await compile(
                    identifier: shard.identifier,
                    encodedRules: encodedRules,
                    store: store
                )
            } catch {
                throw ContentRuleBundleError.compilationFailed(
                    "\(shard.identifier): \(error.localizedDescription)"
                )
            }
            ruleLists.append(compiled)
        }

        return PreparedContentRules(
            manifest: manifest,
            ruleLists: ruleLists,
            cosmeticEnforcementScript: WKUserScript(
                source: cosmeticScriptSource,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true,
                in: .defaultClient
            )
        )
    }

    public static func compileForTesting(
        identifier: String,
        encodedRules: String
    ) async throws -> WKContentRuleList {
        try await compileForTesting(
            identifier: identifier,
            encodedRules: encodedRules,
            store: .default()
        )
    }

    public static func compileForTesting(
        identifier: String,
        encodedRules: String,
        store: WKContentRuleListStore
    ) async throws -> WKContentRuleList {
        try await compile(
            identifier: identifier,
            encodedRules: encodedRules,
            store: store
        )
    }

    private static func resourceURL(
        named name: String,
        bundle: Bundle
    ) throws -> URL {
        let pathExtension = (name as NSString).pathExtension
        let resourceName = (name as NSString).deletingPathExtension
        if let url = bundle.url(
            forResource: resourceName,
            withExtension: pathExtension,
            subdirectory: "ContentRules"
        ) ?? bundle.url(
            forResource: resourceName,
            withExtension: pathExtension
        ) {
            return url
        }
        throw ContentRuleBundleError.missingResource(name)
    }

    private static func textResource(
        named name: String,
        bundle: Bundle
    ) throws -> String {
        let url = try resourceURL(named: name, bundle: bundle)
        guard let text = String(
            data: try Data(contentsOf: url),
            encoding: .utf8
        ) else {
            throw ContentRuleBundleError.invalidText(name)
        }
        return text
    }

    private static func lookup(
        identifier: String,
        store: WKContentRuleListStore
    ) async throws -> WKContentRuleList {
        try await withCheckedThrowingContinuation { continuation in
            store.lookUpContentRuleList(forIdentifier: identifier) { list, error in
                if let list {
                    continuation.resume(returning: list)
                } else {
                    continuation.resume(
                        throwing: error ?? ContentRuleBundleError.compilationFailed(identifier)
                    )
                }
            }
        }
    }

    private static func compile(
        identifier: String,
        encodedRules: String,
        store: WKContentRuleListStore
    ) async throws -> WKContentRuleList {
        try await withCheckedThrowingContinuation { continuation in
            store.compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: encodedRules
            ) { list, error in
                if let list {
                    continuation.resume(returning: list)
                } else {
                    continuation.resume(
                        throwing: error ?? ContentRuleBundleError.compilationFailed(identifier)
                    )
                }
            }
        }
    }
}

@MainActor
public final class ContentProtectionStore: ObservableObject {
    @Published public private(set) var allowlistedHosts: Set<String>

    private let defaults: UserDefaults
    private let keyPrefix: String

    public init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "context.content-protection"
    ) {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
        self.allowlistedHosts = Set(
            defaults.stringArray(forKey: "\(keyPrefix).allowlisted-hosts") ?? []
        )
    }

    public func isBlocking(url: URL?) -> Bool {
        guard let host = normalizedHost(url?.host()) else {
            return true
        }
        return !allowlistedHosts.contains(host)
    }

    public func setBlocking(_ enabled: Bool, for url: URL?) {
        guard let host = normalizedHost(url?.host()) else {
            return
        }
        if enabled {
            allowlistedHosts.remove(host)
        } else {
            allowlistedHosts.insert(host)
        }
        defaults.set(
            allowlistedHosts.sorted(),
            forKey: "\(keyPrefix).allowlisted-hosts"
        )
    }

    private func normalizedHost(_ host: String?) -> String? {
        host?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
    }
}
