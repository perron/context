// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Combine
import Foundation

public enum ContentRuleStatus: Equatable {
    case preparing
    case ready(ruleCount: Int)
    case failed(String)
}

@MainActor
public final class BrowserStore: ObservableObject {
    @Published public private(set) var tabs: [BrowserTab]
    @Published public var selectedTabID: BrowserTab.ID
    @Published public private(set) var contentRuleStatus: ContentRuleStatus = .preparing
    public let protectionStore: ContentProtectionStore
    public var externalURLHandler: (URL) -> Void = { _ in }
    private var preparedContentRules: PreparedContentRules?

    public init(protectionStore: ContentProtectionStore? = nil) {
        let protectionStore = protectionStore ?? ContentProtectionStore()
        self.protectionStore = protectionStore
        let firstTab = BrowserTab()
        self.tabs = [firstTab]
        self.selectedTabID = firstTab.id
        connectNavigation(for: firstTab)
    }

    public var selectedTab: BrowserTab {
        tabs.first(where: { $0.id == selectedTabID }) ?? tabs[0]
    }

    public var canGoBack: Bool {
        !selectedTab.page.backForwardList.backList.isEmpty
    }

    public var canGoForward: Bool {
        !selectedTab.page.backForwardList.forwardList.isEmpty
    }

    @discardableResult
    public func addTab(select: Bool = true) -> BrowserTab {
        let tab = BrowserTab()
        connectNavigation(for: tab)
        if let preparedContentRules {
            tab.installContentRules(preparedContentRules)
        }
        tabs.append(tab)
        if select {
            selectedTabID = tab.id
        }
        return tab
    }

    public func select(_ id: BrowserTab.ID) {
        guard tabs.contains(where: { $0.id == id }) else {
            return
        }
        selectedTabID = id
    }

    public func close(_ id: BrowserTab.ID) {
        guard let removedIndex = tabs.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removedSelectedTab = id == selectedTabID
        tabs.remove(at: removedIndex)

        if tabs.isEmpty {
            addTab()
        } else if removedSelectedTab {
            selectedTabID = tabs[min(removedIndex, tabs.count - 1)].id
        }
    }

    public func navigate(to url: URL) {
        objectWillChange.send()
        selectedTab.isNewTab = false
        selectedTab.setContentBlockingEnabled(
            protectionStore.isBlocking(url: url)
        )
        selectedTab.page.load(url)
    }

    @discardableResult
    public func openInNewTab(_ url: URL) -> BrowserTab {
        let tab = addTab()
        navigate(to: url)
        return tab
    }

    public func loadHTML(_ html: String, baseURL: URL) {
        objectWillChange.send()
        selectedTab.isNewTab = false
        selectedTab.setContentBlockingEnabled(
            protectionStore.isBlocking(url: baseURL)
        )
        selectedTab.page.load(html: html, baseURL: baseURL)
    }

    public func prepareContentBlocking(bundle: Bundle) async {
        contentRuleStatus = .preparing
        do {
            let preparedContentRules = try await ContentRuleBundleLoader.prepare(
                bundle: bundle
            )
            self.preparedContentRules = preparedContentRules
            for tab in tabs {
                tab.installContentRules(preparedContentRules)
                tab.setContentBlockingEnabled(
                    protectionStore.isBlocking(url: tab.page.url)
                )
                if !tab.isNewTab, tab.page.url != nil {
                    tab.page.reload()
                }
            }
            contentRuleStatus = .ready(
                ruleCount: preparedContentRules.manifest.totalRuleCount
            )
        } catch {
            contentRuleStatus = .failed(error.localizedDescription)
        }
    }

    public var isBlockingSelectedSite: Bool {
        protectionStore.isBlocking(url: selectedTab.page.url)
    }

    public func setBlockingForSelectedSite(_ enabled: Bool) {
        protectionStore.setBlocking(enabled, for: selectedTab.page.url)
        selectedTab.setContentBlockingEnabled(enabled)
        selectedTab.page.reload()
    }

    public func goBack() {
        guard let item = selectedTab.page.backForwardList.backList.last else {
            return
        }
        selectedTab.page.load(item)
    }

    public func goForward() {
        guard let item = selectedTab.page.backForwardList.forwardList.first else {
            return
        }
        selectedTab.page.load(item)
    }

    public func reloadOrStop() {
        if selectedTab.page.isLoading {
            selectedTab.page.stopLoading()
        } else {
            selectedTab.page.reload()
        }
    }

    private func connectNavigation(for tab: BrowserTab) {
        tab.navigationRouter.route = { [weak self] disposition in
            self?.handle(disposition)
        }
        tab.navigationRouter.willNavigate = { [weak self, weak tab] url in
            guard let self, let tab else {
                return
            }
            tab.setContentBlockingEnabled(
                self.protectionStore.isBlocking(url: url)
            )
        }
    }

    private func handle(_ disposition: BrowserNavigationDisposition) {
        switch disposition {
        case .allow, .cancel:
            break
        case .openContextTab(let url):
            openInNewTab(url)
        case .openExternal(let url):
            externalURLHandler(url)
        }
    }
}
