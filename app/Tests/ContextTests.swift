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
}
