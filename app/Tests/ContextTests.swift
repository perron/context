// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest
import BrowserKit
@testable import Context

final class ContextTests: XCTestCase {
    func testAppTargetLoads() {
        XCTAssertTrue(true)
    }

    @MainActor
    func testBundledContentRulesCompile() async throws {
        let preparedRules = try await ContentRuleBundleLoader.prepare(
            bundle: .main
        )

        XCTAssertEqual(
            preparedRules.ruleLists.count,
            preparedRules.manifest.shards.count
        )
        XCTAssertGreaterThan(preparedRules.manifest.totalRuleCount, 100_000)
    }

    @MainActor
    func testBookmarksAndHistoryPersistLocally() throws {
        let suiteName = "ContextTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let pageURL = try XCTUnwrap(URL(string: "https://example.com/article#section"))

        let library = BrowserLibraryStore(
            defaults: defaults,
            keyPrefix: "test.library"
        )
        library.toggleBookmark(title: "Example article", url: pageURL)
        library.recordHistory(title: "Example article", url: pageURL)

        XCTAssertTrue(library.isBookmarked(pageURL))
        XCTAssertEqual(library.bookmarks.count, 1)
        XCTAssertEqual(library.history.count, 1)
        XCTAssertEqual(library.bookmarks[0].urlString, "https://example.com/article")

        let reloaded = BrowserLibraryStore(
            defaults: defaults,
            keyPrefix: "test.library"
        )
        XCTAssertEqual(reloaded.bookmarks, library.bookmarks)
        XCTAssertEqual(reloaded.history, library.history)
    }

    func testGrokHandoffIncludesReviewedPageContext() throws {
        let pageURL = try XCTUnwrap(URL(string: "https://example.com/article"))
        let readableText = String(repeating: "x", count: 24_001)
        let handoff = GrokHandoffContent(
            task: "Summarize the evidence.",
            pageTitle: "Example article",
            pageURL: pageURL,
            readableText: readableText,
            includeReadableText: true
        )

        XCTAssertTrue(handoff.prompt.contains("Task: Summarize the evidence."))
        XCTAssertTrue(handoff.prompt.contains("Page title: Example article"))
        XCTAssertTrue(handoff.prompt.contains("Page URL: https://example.com/article"))
        XCTAssertTrue(handoff.prompt.contains(String(repeating: "x", count: 24_000)))
        XCTAssertFalse(handoff.prompt.contains(String(repeating: "x", count: 24_001)))
        XCTAssertTrue(handoff.prompt.contains("untrusted website content"))
    }

    func testGrokHandoffCanExcludeReadableText() {
        let handoff = GrokHandoffContent(
            task: "",
            pageTitle: "Private page",
            pageURL: nil,
            readableText: "Sensitive text",
            includeReadableText: false
        )

        XCTAssertTrue(handoff.prompt.contains("Task: Help me with this page."))
        XCTAssertFalse(handoff.prompt.contains("Sensitive text"))
        XCTAssertFalse(handoff.prompt.contains("Readable page text"))
    }

    func testXPostUsesOfficialReviewableWebIntent() throws {
        let pageURL = try XCTUnwrap(URL(string: "https://example.com/article?ref=context"))
        let intent = ContextLinks.xPostIntent(
            title: "  Useful   article\nfor everyone  ",
            url: pageURL
        )
        let components = try XCTUnwrap(URLComponents(url: intent, resolvingAgainstBaseURL: false))
        let query = Dictionary(
            uniqueKeysWithValues: try XCTUnwrap(components.queryItems).map { ($0.name, $0.value) }
        )

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "x.com")
        XCTAssertEqual(components.path, "/intent/tweet")
        XCTAssertEqual(query["text"]!, "Reading: Useful article for everyone")
        XCTAssertEqual(query["url"]!, pageURL.absoluteString)
    }
}
