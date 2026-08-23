// swift-tools-version: 6.2
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import PackageDescription

let package = Package(
    name: "BrowserKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "BrowserKit", targets: ["BrowserKit"])],
    targets: [
        .target(name: "BrowserKit", path: "Sources"),
        .testTarget(name: "BrowserKitTests", dependencies: ["BrowserKit"], path: "Tests")
    ]
)
