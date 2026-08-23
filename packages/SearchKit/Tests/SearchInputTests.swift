// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest
@testable import SearchKit

final class SearchInputTests: XCTestCase {
    func testPreservesHTTPSURL() {
        let url = SearchInput.resolve("https://example.com/page")

        XCTAssertEqual(url?.absoluteString, "https://example.com/page")
    }

    func testAddsHTTPSForHost() {
        let url = SearchInput.resolve("example.com/page")

        XCTAssertEqual(url?.absoluteString, "https://example.com/page")
    }

    func testBuildsSearchURLForWords() {
        let url = SearchInput.resolve("context browser")
        let components = url.flatMap {
            URLComponents(url: $0, resolvingAgainstBaseURL: false)
        }

        XCTAssertEqual(components?.host, "www.google.com")
        XCTAssertEqual(components?.queryItems?.first?.value, "context browser")
    }

    func testReturnsNilForWhitespace() {
        XCTAssertNil(SearchInput.resolve("   "))
    }
}
