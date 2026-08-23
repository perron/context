// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

public struct ReaderDocument: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let byline: String?
    public let body: String
    public let sourceURL: URL?
}

public enum ReaderDocumentError: LocalizedError {
    case unavailable

    public var errorDescription: String? {
        "Reader mode could not find enough article text on this page."
    }
}

extension BrowserStore {
    public func makeReaderDocument() async throws -> ReaderDocument {
        let result = try await selectedTab.page.callJavaScript(
            """
            const article = document.querySelector("article") || document.querySelector("main") || document.body;
            const paragraphs = Array.from(article.querySelectorAll("p"))
              .map(node => node.innerText.trim())
              .filter(text => text.length > 24);
            return {
              title: document.querySelector("article h1, main h1, h1")?.innerText.trim() || document.title,
              byline: document.querySelector("[rel=author], .byline, [class*=author]")?.innerText.trim() || "",
              body: paragraphs.join("\\n\\n"),
              url: location.href
            };
            """
        )
        guard let payload = result as? [String: Any],
              let title = payload["title"] as? String,
              let body = payload["body"] as? String,
              body.count > 120 else {
            throw ReaderDocumentError.unavailable
        }
        let byline = (payload["byline"] as? String).flatMap {
            $0.isEmpty ? nil : $0
        }
        let sourceURL = (payload["url"] as? String).flatMap(URL.init(string:))
        return ReaderDocument(
            title: title,
            byline: byline,
            body: body,
            sourceURL: sourceURL
        )
    }
}
