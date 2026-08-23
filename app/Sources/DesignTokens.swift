// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import UIKit

extension Color {
    static let contextNight = Color(
        red: 0.025,
        green: 0.039,
        blue: 0.060
    )

    static let contextNightRaised = Color(
        red: 0.067,
        green: 0.086,
        blue: 0.118
    )

    static let contextNightText = Color(
        red: 0.965,
        green: 0.957,
        blue: 0.933
    )

    static let contextTint = Color(
        red: 0.439,
        green: 0.702,
        blue: 0.941
    )

    static let contextInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.965, green: 0.957, blue: 0.933, alpha: 1)
            : UIColor(red: 0.078, green: 0.090, blue: 0.110, alpha: 1)
    })

    static let contextPaper = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.078, green: 0.090, blue: 0.110, alpha: 1)
            : UIColor(red: 0.965, green: 0.957, blue: 0.933, alpha: 1)
    })

    static let contextCard = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.125, green: 0.141, blue: 0.165, alpha: 1)
            : UIColor(red: 0.995, green: 0.992, blue: 0.980, alpha: 1)
    })

    static let contextAgent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.439, green: 0.702, blue: 0.941, alpha: 1)
            : UIColor(red: 0.102, green: 0.424, blue: 0.710, alpha: 1)
    })
}

struct NightSkyBackground: View {
    var body: some View {
        Canvas { context, size in
            let bounds = Path(CGRect(origin: .zero, size: size))
            context.fill(
                bounds,
                with: .linearGradient(
                    Gradient(colors: [
                        .contextNight,
                        Color(red: 0.035, green: 0.055, blue: 0.084),
                        Color(red: 0.018, green: 0.028, blue: 0.044)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )

            for index in 0..<86 {
                let horizontalPosition = unit(index, salt: 17) * size.width
                let verticalPosition = unit(index, salt: 53) * size.height
                let diameter = 0.8 + unit(index, salt: 91) * 2.1
                let opacity = 0.18 + unit(index, salt: 131) * 0.62
                let star = Path(
                    ellipseIn: CGRect(
                        x: horizontalPosition,
                        y: verticalPosition,
                        width: diameter,
                        height: diameter
                    )
                )
                context.fill(
                    star,
                    with: .color(.white.opacity(opacity))
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func unit(_ index: Int, salt: Int) -> CGFloat {
        let raw = sin(Double(index * 997 + salt * 37)) * 10_000
        return CGFloat(raw - floor(raw))
    }
}
