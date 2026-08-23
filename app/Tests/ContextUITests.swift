// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import XCTest
import UIKit

final class ContextUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testNewTabShellAndCaptureScreenshot() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.textFields["Search or enter website"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Quick Links"].exists)
        XCTAssertTrue(app.buttons["Ask your Grok Bot"].exists)
        XCTAssertTrue(app.buttons["Ask Grok Bot"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Context 1.0 New Tab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testTargetBlankOpensContextTabAndStaysForeground() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-test-target-blank"
        ]
        app.launch()

        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 5))
        webView.coordinate(withNormalizedOffset: CGVector(dx: 0.38, dy: 0.28)).tap()

        XCTAssertTrue(app.buttons["2 tabs"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.state, .runningForeground)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Context 1.0 Target Blank Tab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testContentBlockingAllowlistAndReader() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-test-content-blocking"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["A quieter web"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Protection on"].waitForExistence(timeout: 5))
        app.buttons["Protection on"].tap()

        XCTAssertTrue(app.buttons["Turn off for this site"].exists)
        addScreenshot(named: "Context 1.0 Protection On")

        app.buttons["Turn off for this site"].tap()
        XCTAssertTrue(app.buttons["Protection off"].waitForExistence(timeout: 5))
        app.buttons["Protection off"].tap()
        XCTAssertTrue(app.buttons["Turn on for this site"].exists)
        addScreenshot(named: "Context 1.0 Protection Off")

        app.buttons["Turn on for this site"].tap()
        XCTAssertTrue(app.buttons["Protection on"].waitForExistence(timeout: 5))
        app.buttons["Protection on"].tap()
        app.buttons["Reader"].tap()

        XCTAssertTrue(app.navigationBars["Reader"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["A quieter web"].exists)
        addScreenshot(named: "Context 1.0 Reader")
        app.buttons["Done"].tap()
    }

    @MainActor
    func testIPadSidebarCanHideAndShow() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("The persistent tab sidebar is an iPad layout.")
        }

        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-test-sidebar-expanded"
        ]
        app.launch()

        let hideButton = app.buttons["hideTabsSidebarButton"]
        XCTAssertTrue(hideButton.waitForExistence(timeout: 5))
        hideButton.tap()

        let showButton = app.buttons["showTabsSidebarButton"]
        XCTAssertTrue(showButton.waitForExistence(timeout: 5))
        addScreenshot(named: "Context 1.0 iPad Sidebar Collapsed")
        showButton.tap()

        XCTAssertTrue(hideButton.waitForExistence(timeout: 5))
        addScreenshot(named: "Context 1.0 iPad Sidebar Expanded")
    }

    private func addScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIApplication().screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
