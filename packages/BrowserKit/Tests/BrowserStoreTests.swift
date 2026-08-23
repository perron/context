// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest
@testable import BrowserKit

final class BrowserStoreTests: XCTestCase {
    @MainActor
    func testStoreAlwaysKeepsOneTab() {
        let store = BrowserStore()
        let initialID = store.selectedTabID

        store.close(initialID)

        XCTAssertEqual(store.tabs.count, 1)
        XCTAssertTrue(store.selectedTab.isNewTab)
    }

    @MainActor
    func testNewTabBecomesSelected() {
        let store = BrowserStore()
        let tab = store.addTab()

        XCTAssertEqual(store.tabs.count, 2)
        XCTAssertEqual(store.selectedTabID, tab.id)
    }

    @MainActor
    func testOpeningURLInNewTabSelectsAndNavigates() {
        let store = BrowserStore()
        let url = URL(string: "https://grok.com")!

        let tab = store.openInNewTab(url)

        XCTAssertEqual(store.tabs.count, 2)
        XCTAssertEqual(store.selectedTabID, tab.id)
        XCTAssertFalse(tab.isNewTab)
        XCTAssertEqual(tab.page.url?.host(), url.host())
    }

    @MainActor
    func testClosingSelectedTabChoosesNeighbor() {
        let store = BrowserStore()
        let secondTab = store.addTab()
        let thirdTab = store.addTab()
        store.select(secondTab.id)

        store.close(secondTab.id)

        XCTAssertEqual(store.selectedTabID, thirdTab.id)
    }

    func testNewWindowHTTPLinkOpensContextTab() {
        let url = URL(string: "https://example.com/new")!

        let disposition = BrowserNavigationPolicy.disposition(
            for: url,
            requestsNewWindow: true
        )

        XCTAssertEqual(disposition, .openContextTab(url))
    }

    func testSameWindowHTTPLinkStaysInCurrentTab() {
        let disposition = BrowserNavigationPolicy.disposition(
            for: URL(string: "https://example.com"),
            requestsNewWindow: false
        )

        XCTAssertEqual(disposition, .allow)
    }

    func testExternalSchemeLeavesContext() {
        let url = URL(string: "mailto:hello@example.com")!

        let disposition = BrowserNavigationPolicy.disposition(
            for: url,
            requestsNewWindow: false
        )

        XCTAssertEqual(disposition, .openExternal(url))
    }

    func testAppStoreWebLinkLeavesContext() {
        let url = URL(string: "https://apps.apple.com/app/id123")!

        let disposition = BrowserNavigationPolicy.disposition(
            for: url,
            requestsNewWindow: false
        )

        XCTAssertEqual(disposition, .openExternal(url))
    }

    func testContentRuleJSONStructureIsValid() throws {
        let rules = """
        [{
          "trigger": {"url-filter": ".*"},
          "action": {"type": "block"}
        }]
        """

        let decoded = try JSONSerialization.jsonObject(
            with: Data(rules.utf8)
        )

        XCTAssertNotNil(decoded as? [[String: Any]])
    }

    @MainActor
    func testAllowlistPersistenceRoundTrips() {
        let suiteName = "context-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let url = URL(string: "https://news.example/article")!
        let firstStore = ContentProtectionStore(
            defaults: defaults,
            keyPrefix: "test"
        )

        firstStore.setBlocking(false, for: url)
        let secondStore = ContentProtectionStore(
            defaults: defaults,
            keyPrefix: "test"
        )

        XCTAssertFalse(secondStore.isBlocking(url: url))
    }

}
