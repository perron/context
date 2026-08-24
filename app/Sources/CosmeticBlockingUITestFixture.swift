// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BrowserKit
import Foundation

@MainActor
enum CosmeticBlockingUITestFixture {
    static func configure(browser: BrowserStore) {
        #if DEBUG
        guard isRequested,
              let yahooURL = URL(string: "https://www.yahoo.com/") else {
            return
        }
        browser.protectionStore.setBlocking(
            !ProcessInfo.processInfo.arguments.contains(
                "--ui-test-protection-off"
            ),
            for: yahooURL
        )
        #endif
    }

    static func load(into browser: BrowserStore) {
        #if DEBUG
        guard isRequested,
              let fixtureURL = Bundle.main.url(
                  forResource: "CosmeticBlockingFixture",
                  withExtension: "html"
              ),
              let html = try? String(contentsOf: fixtureURL, encoding: .utf8),
              let baseURL = URL(string: "https://www.yahoo.com/") else {
            return
        }
        browser.loadHTML(html, baseURL: baseURL)
        #endif
    }

    #if DEBUG
    private static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains(
            "--ui-test-cosmetic-blocking"
        )
    }
    #endif
}
