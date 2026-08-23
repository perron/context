// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

public enum SearchEngine: String, CaseIterable, Codable, Sendable {
    case google
    case bing
    case duckDuckGo
    case brave
    case kagi
    case ecosia

    public var title: String {
        switch self {
        case .google: "Google"
        case .bing: "Bing"
        case .duckDuckGo: "DuckDuckGo"
        case .brave: "Brave"
        case .kagi: "Kagi"
        case .ecosia: "Ecosia"
        }
    }

    public func searchURL(for query: String) -> URL {
        var components: URLComponents

        switch self {
        case .google:
            components = URLComponents(string: "https://www.google.com/search")!
        case .bing:
            components = URLComponents(string: "https://www.bing.com/search")!
        case .duckDuckGo:
            components = URLComponents(string: "https://duckduckgo.com/")!
        case .brave:
            components = URLComponents(string: "https://search.brave.com/search")!
        case .kagi:
            components = URLComponents(string: "https://kagi.com/search")!
        case .ecosia:
            components = URLComponents(string: "https://www.ecosia.org/search")!
        }

        components.queryItems = [URLQueryItem(name: "q", value: query)]
        return components.url!
    }
}
public enum SearchInput {
    public static func resolve(_ input: String, engine: SearchEngine = .google) -> URL? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            return nil
        }

        if let url = URL(string: value),
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            return url
        }

        if looksLikeHost(value) {
            let scheme = value.hasPrefix("localhost") ? "http" : "https"
            return URL(string: "\(scheme)://\(value)")
        }

        return engine.searchURL(for: value)
    }

    private static func looksLikeHost(_ value: String) -> Bool {
        !value.contains(where: \.isWhitespace)
            && (value.contains(".") || value.hasPrefix("localhost"))
    }
}
