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
        XCTAssertTrue(app.buttons["Ask Grok"].exists)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Context 1.0 New Tab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testAddressEntryNavigatesInsideContext() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let addressField = app.textFields["Search or enter website"]
        XCTAssertTrue(addressField.waitForExistence(timeout: 5))
        addressField.tap()
        addressField.typeText("example.com\n")

        XCTAssertTrue(
            app.webViews.firstMatch.waitForExistence(timeout: 15),
            "Typing a normal URL must load Context's embedded WebView."
        )
        XCTAssertEqual(
            app.state,
            .runningForeground,
            "Typing a normal URL must not hand navigation to Safari."
        )
        XCTAssertTrue(
            String(describing: addressField.value).contains("example.com"),
            "The address bar should continue to show the page loaded by Context."
        )
    }

    @MainActor
    func testAskGrokReviewShowsExplicitDestinations() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-test-content-blocking",
            "--ui-test-clear-ai-keys"
        ]
        app.launch()

        let askGrok = app.buttons["Ask Grok"].firstMatch
        XCTAssertTrue(askGrok.waitForExistence(timeout: 20))
        askGrok.tap()

        XCTAssertTrue(app.navigationBars["Ask Grok"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["set-up-ai-provider-button"].exists)
        XCTAssertTrue(app.buttons["Share to Grok…"].exists)
        addScreenshot(named: "Context 1.0 Ask Grok API Setup")

        app.buttons["Assistant options"].tap()
        XCTAssertTrue(app.buttons["AI Provider Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Open Grok Bot"].exists)
        XCTAssertTrue(app.buttons["Post on X"].exists)
        XCTAssertTrue(app.buttons["Copy prompt"].exists)
        addScreenshot(named: "Context 1.0 Ask Grok Secondary Actions")
    }

    @MainActor
    func testConfiguredGrokAPIShowsNativeChatAndReviewedContext() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-test-content-blocking",
            "--ui-test-clear-ai-keys",
            "--ui-test-ai-configured"
        ]
        app.launch()

        let askGrok = app.buttons["Ask Grok"].firstMatch
        XCTAssertTrue(askGrok.waitForExistence(timeout: 20))
        askGrok.tap()

        XCTAssertTrue(app.navigationBars["Ask Grok"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Grok (xAI API)"].exists)
        XCTAssertTrue(app.textFields["ai-chat-composer"].exists)
        XCTAssertTrue(app.buttons["Send to Grok"].exists)
        XCTAssertTrue(app.staticTexts["Page context"].exists)
        XCTAssertEqual(
            app.switches["Include readable page text"].value as? String,
            "1",
            "Readable page text should be included by default after the user reviews the context."
        )
        addScreenshot(named: "Context 1.0 Grok API Chat")
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

        let newWindowLink = app.links["Open example.com"]
        XCTAssertTrue(newWindowLink.waitForExistence(timeout: 5))
        newWindowLink.tap()

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

    @MainActor
    func testFixedBottomPopupStaysAboveBrowserChrome() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-test-bottom-popup"
        ]
        app.launch()

        let popupButton = app.buttons["Fixture popup close"]
        let backButton = app.buttons["Back"]
        XCTAssertTrue(popupButton.waitForExistence(timeout: 5))
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        XCTAssertTrue(popupButton.isHittable)
        XCTAssertLessThanOrEqual(popupButton.frame.maxY, backButton.frame.minY)
        addScreenshot(named: "Context 1.0 Fixed Bottom Popup")
    }

    @MainActor
    func testSettingsExposeWebsiteDataAndFilterAttribution() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(app.buttons["More"].waitForExistence(timeout: 5))
        app.buttons["More"].tap()
        let settingsButton = app.buttons["more-settings-button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        let providerSettings = app.buttons["ai-provider-settings-link"]
        XCTAssertTrue(providerSettings.waitForExistence(timeout: 5))
        providerSettings.tap()
        XCTAssertTrue(app.navigationBars["AI Providers"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ai-provider-xAI"].exists)
        XCTAssertTrue(app.buttons["ai-provider-openAI"].exists)
        XCTAssertTrue(app.buttons["ai-provider-anthropic"].exists)
        XCTAssertTrue(app.buttons["ai-provider-gemini"].exists)
        addScreenshot(named: "Context 1.0 AI Providers")
        app.navigationBars["AI Providers"].buttons.firstMatch.tap()

        let clearWebsiteData = app.buttons["clear-website-data-button"]
        if !clearWebsiteData.exists {
            app.swipeUp()
        }
        XCTAssertTrue(clearWebsiteData.waitForExistence(timeout: 5))
        app.swipeUp()
        let attribution = app.descendants(matching: .any)["easylist-attribution-link"]
        if !attribution.exists {
            app.swipeUp()
        }
        XCTAssertTrue(attribution.waitForExistence(timeout: 5))
        addScreenshot(named: "Context 1.0 Privacy and Attribution")
    }

    @MainActor
    func testExternalURLRequiresConfirmation() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-test-external-url"
        ]
        app.launch()

        let externalLink = app.links["Email example"]
        XCTAssertTrue(externalLink.waitForExistence(timeout: 5))
        externalLink.tap()

        XCTAssertTrue(app.alerts["Open another app?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["mailto:hello@example.com"].exists)
        app.alerts["Open another app?"].buttons["Cancel"].tap()
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    private func addScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIApplication().screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
