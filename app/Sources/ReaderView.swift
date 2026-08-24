// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BrowserKit
import SwiftUI

struct ReaderView: View {
    let document: ReaderDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(document.title)
                        .font(.largeTitle.bold())
                        .textSelection(.enabled)

                    if let byline = document.byline {
                        Text(byline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(document.body)
                        .font(.body)
                        .lineSpacing(7)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .background(Color.contextPaper)
            .navigationTitle("Reader")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
