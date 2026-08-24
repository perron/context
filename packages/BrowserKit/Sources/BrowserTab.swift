// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Combine
import Foundation
import WebKit

@MainActor
public final class BrowserTab: ObservableObject, Identifiable {
    public let id: UUID
    public let page: WebPage
    public let navigationRouter: BrowserNavigationRouter
    public let userContentController: WKUserContentController
    @Published public var isNewTab: Bool
    private var preparedContentRules: PreparedContentRules?
    private var isContentBlockingEnabled = true

    public init(
        id: UUID = UUID(),
        isNewTab: Bool = true
    ) {
        self.id = id
        self.isNewTab = isNewTab
        let navigationRouter = BrowserNavigationRouter()
        let userContentController = WKUserContentController()
        var configuration = WebPage.Configuration()
        configuration.userContentController = userContentController
        self.navigationRouter = navigationRouter
        self.userContentController = userContentController
        self.page = WebPage(
            configuration: configuration,
            navigationDecider: BrowserNavigationDecider(router: navigationRouter)
        )
    }

    public var title: String {
        if isNewTab {
            return "New Tab"
        }

        let pageTitle = page.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pageTitle.isEmpty {
            return pageTitle
        }

        return page.url?.host() ?? "Untitled"
    }

    public var displayURL: String {
        page.url?.absoluteString ?? ""
    }

    public func installContentRules(_ preparedContentRules: PreparedContentRules) {
        self.preparedContentRules = preparedContentRules
        applyContentBlockingState()
    }

    public func setContentBlockingEnabled(_ enabled: Bool) {
        guard isContentBlockingEnabled != enabled else {
            return
        }
        isContentBlockingEnabled = enabled
        applyContentBlockingState()
    }

    private func applyContentBlockingState() {
        userContentController.removeAllContentRuleLists()
        userContentController.removeAllUserScripts()
        guard isContentBlockingEnabled, let preparedContentRules else {
            return
        }
        userContentController.addUserScript(
            preparedContentRules.cosmeticEnforcementScript
        )
        for ruleList in preparedContentRules.ruleLists {
            userContentController.add(ruleList)
        }
    }
}
