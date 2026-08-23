// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

enum ContextLinks {
    static let grok = URL(string: "https://grok.com")!
    static let xHome = URL(string: "https://x.com")!
    static let grokBotOpen = URL(string: "grokbot://app/v1/open")!
    static let grokBotHelp = URL(
        string: "https://cursor.com/help/grok-bot/mobile"
    )!
    static let source = URL(string: "https://github.com/perron/context")!
    static let privacy = URL(
        string: "https://perron.github.io/context/privacy/"
    )!
    static let support = URL(
        string: "https://perron.github.io/context/support/"
    )!

    static func xPostIntent(title: String, url: URL?) -> URL {
        let cleanTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        let postText = cleanTitle.isEmpty
            ? "Shared from Context"
            : "Reading: \(String(cleanTitle.prefix(180)))"

        var components = URLComponents(string: "https://x.com/intent/tweet")!
        components.queryItems = [URLQueryItem(name: "text", value: postText)]
        if let url {
            components.queryItems?.append(
                URLQueryItem(name: "url", value: url.absoluteString)
            )
        }
        return components.url!
    }
}
