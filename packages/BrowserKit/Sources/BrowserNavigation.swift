// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

public enum BrowserNavigationDisposition: Equatable, Sendable {
    case allow
    case openContextTab(URL)
    case openExternal(URL)
}

public enum BrowserNavigationPolicy {
    private static let systemWebHosts = [
        "apps.apple.com",
        "maps.apple.com"
    ]

    public static func disposition(
        for url: URL?,
        requestsNewWindow: Bool
    ) -> BrowserNavigationDisposition {
        guard let url, let scheme = url.scheme?.lowercased() else {
            return .allow
        }

        if ["file", "about", "data", "blob"].contains(scheme) {
            return .allow
        }

        guard scheme == "http" || scheme == "https" else {
            return .openExternal(url)
        }

        if let host = url.host()?.lowercased(),
           systemWebHosts.contains(where: { host == $0 || host.hasSuffix(".\($0)") }) {
            return .openExternal(url)
        }

        return requestsNewWindow ? .openContextTab(url) : .allow
    }
}

@MainActor
public final class BrowserNavigationRouter {
    public var route: (BrowserNavigationDisposition) -> Void
    public var willNavigate: (URL) -> Void

    public init(
        route: @escaping (BrowserNavigationDisposition) -> Void = { _ in },
        willNavigate: @escaping (URL) -> Void = { _ in }
    ) {
        self.route = route
        self.willNavigate = willNavigate
    }
}

public struct BrowserNavigationDecider: WebPage.NavigationDeciding {
    private let router: BrowserNavigationRouter

    @MainActor
    public init(router: BrowserNavigationRouter) {
        self.router = router
    }

    @MainActor
    public mutating func decidePolicy(
        for action: WebPage.NavigationAction,
        preferences: inout WebPage.NavigationPreferences
    ) async -> WKNavigationActionPolicy {
        if action.target?.isMainFrame == true, let url = action.request.url {
            router.willNavigate(url)
        }
        let disposition = BrowserNavigationPolicy.disposition(
            for: action.request.url,
            requestsNewWindow: action.target == nil
        )

        switch disposition {
        case .allow:
            return .allow
        case .openContextTab, .openExternal:
            router.route(disposition)
            return .cancel
        }
    }
}
