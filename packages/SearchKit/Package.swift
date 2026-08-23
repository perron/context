// swift-tools-version: 6.2
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import PackageDescription

let package = Package(
    name: "SearchKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "SearchKit", targets: ["SearchKit"])],
    targets: [
        .target(name: "SearchKit", path: "Sources"),
        .testTarget(name: "SearchKitTests", dependencies: ["SearchKit"], path: "Tests")
    ]
)
