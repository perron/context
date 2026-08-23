// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BrowserKit
import SwiftUI

@main
struct ContextApp: App {
    @StateObject private var browser = BrowserStore()

    var body: some Scene {
        WindowGroup {
            BrowserRootView(browser: browser)
        }
    }
}
