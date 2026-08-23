// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BrowserKit
import SearchKit
import SwiftUI
import UIKit
import WebKit

// THESIS: Context turns the current page into a deliberate Grok handoff.
// OWN-WORLD: Night Atlas uses abyssal navy, warm white, sparse stars, one blue tint, and native iOS material.
// STORY: Browse, tap the signal, verify the page bundle, then choose where it leaves the device.
// FIRST VIEWPORT: A quiet star field frames the promise, quick links, protection, and a floating browser island.
// FORM: Native browser observatory, grounded direction 4, seed c8b13105.
// FINISH: Reviewed, documented in DESIGN.md, and every shipping raster carries provenance.
struct BrowserRootView: View {
    @ObservedObject var browser: BrowserStore
    @StateObject private var library = BrowserLibraryStore()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("isIPadSidebarVisible") private var isIPadSidebarVisible = true
    @State private var addressInput = ""
    @State private var isShowingTabs = false
    @State private var isShowingSettings = false
    @State private var isShowingLibrary = false
    @State private var isShowingAssistant = false
    @State private var didLoadUITestFixture = false
    @State private var readerDocument: ReaderDocument?
    @State private var readerError: String?

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    if isIPadSidebarVisible {
                        BrowserSidebar(
                            browser: browser,
                            hideSidebar: { isIPadSidebarVisible = false },
                            showAssistant: { isShowingAssistant = true },
                            showLibrary: { isShowingLibrary = true },
                            showSettings: { isShowingSettings = true }
                        )
                        .frame(width: 260)

                        Divider()
                    }

                    ZStack(alignment: .topLeading) {
                        browserCanvas

                        if !isIPadSidebarVisible {
                            Button {
                                isIPadSidebarVisible = true
                            } label: {
                                Label("Show tabs", systemImage: "sidebar.left")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .background(.regularMaterial, in: Capsule())
                            .accessibilityIdentifier("showTabsSidebarButton")
                            .padding(12)
                        }
                    }
                }
            } else {
                browserCanvas
            }
        }
        .background(Color.contextPaper)
        .sheet(isPresented: $isShowingTabs) {
            TabSwitcherView(browser: browser)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $isShowingLibrary) {
            LibraryView(library: library, open: browser.navigate)
        }
        .sheet(isPresented: $isShowingAssistant) {
            GrokHandoffSheet(browser: browser)
        }
        .sheet(item: $readerDocument) { document in
            ReaderView(document: document)
        }
        .alert(
            "Reader unavailable",
            isPresented: Binding(
                get: { readerError != nil },
                set: { if !$0 { readerError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(readerError ?? "")
        }
        .onChange(of: browser.selectedTabID, initial: true) {
            syncAddress()
        }
        .onChange(of: browser.selectedTab.page.url) {
            syncAddress()
            recordCurrentPage()
        }
        .onChange(of: browser.selectedTab.page.title) {
            library.refreshTitle(
                browser.selectedTab.title,
                for: browser.selectedTab.page.url
            )
        }
        .onAppear {
            browser.externalURLHandler = { url in
                UIApplication.shared.open(url)
            }
            configureUITestStateIfRequested()
            loadUITestFixtureIfRequested()
        }
        .task {
            await browser.prepareContentBlocking(bundle: .main)
            loadContentBlockingUITestFixtureIfRequested()
        }
    }

    private var browserCanvas: some View {
        ZStack {
            Color.contextPaper.ignoresSafeArea()

            if browser.selectedTab.isNewTab {
                NewTabPage(
                    contentRuleStatus: browser.contentRuleStatus,
                    open: browser.navigate,
                    openGrok: openGrok,
                    showAssistant: { isShowingAssistant = true }
                )
            } else {
                WebView(browser.selectedTab.page)
                    .ignoresSafeArea(edges: .top)

                if browser.selectedTab.page.isLoading {
                    VStack {
                        ProgressView(value: browser.selectedTab.page.estimatedProgress)
                            .tint(.primary)
                            .controlSize(.mini)
                        Spacer()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                if !browser.selectedTab.isNewTab {
                    BrowserNavigationControls(
                        browser: browser,
                        openReader: openReader,
                        showAssistant: { isShowingAssistant = true },
                        showLibrary: { isShowingLibrary = true },
                        isBookmarked: library.isBookmarked(browser.selectedTab.page.url),
                        toggleBookmark: toggleBookmark
                    )
                }

                BrowserBottomBar(
                    addressInput: $addressInput,
                    tabCount: browser.tabs.count,
                    submit: submitAddress,
                    showTabs: { isShowingTabs = true },
                    showLibrary: { isShowingLibrary = true },
                    showSettings: { isShowingSettings = true },
                    openGrok: openGrok,
                    showAssistant: { isShowingAssistant = true }
                )
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.primary.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
            .padding(.horizontal, 10)
            .padding(.bottom, 4)
        }
    }

    private func submitAddress() {
        guard let url = SearchInput.resolve(addressInput) else {
            return
        }
        browser.navigate(to: url)
        addressInput = url.absoluteString
    }

    private func syncAddress() {
        addressInput = browser.selectedTab.displayURL
    }

    private func recordCurrentPage() {
        library.recordHistory(
            title: browser.selectedTab.title,
            url: browser.selectedTab.page.url
        )
    }

    private func toggleBookmark() {
        library.toggleBookmark(
            title: browser.selectedTab.title,
            url: browser.selectedTab.page.url
        )
    }

    private func openGrok() {
        browser.openInNewTab(ContextLinks.grok)
    }

    private func openReader() {
        Task {
            do {
                readerDocument = try await browser.makeReaderDocument()
            } catch {
                readerError = error.localizedDescription
            }
        }
    }

    private func loadUITestFixtureIfRequested() {
        #if DEBUG
        guard !didLoadUITestFixture,
              ProcessInfo.processInfo.arguments.contains("--ui-test-target-blank"),
              let fixtureURL = Bundle.main.url(
                  forResource: "TargetBlankFixture",
                  withExtension: "html"
              ) else {
            return
        }
        didLoadUITestFixture = true
        browser.navigate(to: fixtureURL)
        #endif
    }

    private func configureUITestStateIfRequested() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-test-sidebar-expanded") {
            isIPadSidebarVisible = true
        }
        #endif
    }

    private func loadContentBlockingUITestFixtureIfRequested() {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains(
            "--ui-test-content-blocking"
        ), let fixtureURL = Bundle.main.url(
            forResource: "ContentBlockingFixture",
            withExtension: "html"
        ), let html = try? String(contentsOf: fixtureURL, encoding: .utf8),
        let baseURL = URL(string: "https://context.test/article") else {
            return
        }
        browser.loadHTML(html, baseURL: baseURL)
        #endif
    }
}

private struct BrowserNavigationControls: View {
    @ObservedObject var browser: BrowserStore
    @ObservedObject private var protectionStore: ContentProtectionStore
    let openReader: () -> Void
    let showAssistant: () -> Void
    let showLibrary: () -> Void
    let isBookmarked: Bool
    let toggleBookmark: () -> Void

    init(
        browser: BrowserStore,
        openReader: @escaping () -> Void,
        showAssistant: @escaping () -> Void,
        showLibrary: @escaping () -> Void,
        isBookmarked: Bool,
        toggleBookmark: @escaping () -> Void
    ) {
        self.browser = browser
        self.protectionStore = browser.protectionStore
        self.openReader = openReader
        self.showAssistant = showAssistant
        self.showLibrary = showLibrary
        self.isBookmarked = isBookmarked
        self.toggleBookmark = toggleBookmark
    }

    var body: some View {
        HStack {
            Button(action: browser.goBack) {
                Label("Back", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
            }
            .disabled(!browser.canGoBack)

            Button(action: browser.goForward) {
                Label("Forward", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
            }
            .disabled(!browser.canGoForward)

            Spacer()

            Button(action: showAssistant) {
                Label("Ask Grok Bot", systemImage: "sparkles")
                    .labelStyle(.iconOnly)
            }

            Button(action: browser.reloadOrStop) {
                Label(
                    browser.selectedTab.page.isLoading ? "Stop" : "Reload",
                    systemImage: browser.selectedTab.page.isLoading ? "xmark" : "arrow.clockwise"
                )
                .labelStyle(.iconOnly)
            }

            if let url = browser.selectedTab.page.url {
                ShareLink(item: url) {
                    Label("Share page", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
            }

            Menu {
                Button(action: toggleBookmark) {
                    Label(
                        isBookmarked ? "Remove bookmark" : "Add bookmark",
                        systemImage: isBookmarked ? "bookmark.slash" : "bookmark"
                    )
                }

                Button(action: showLibrary) {
                    Label("Library", systemImage: "books.vertical")
                }

                Button {
                    browser.setBlockingForSelectedSite(
                        !browser.isBlockingSelectedSite
                    )
                } label: {
                    Label(
                        browser.isBlockingSelectedSite
                            ? "Turn off for this site"
                            : "Turn on for this site",
                        systemImage: browser.isBlockingSelectedSite
                            ? "shield.slash"
                            : "shield.checkered"
                    )
                }

                Button(action: openReader) {
                    Label("Reader", systemImage: "text.book.closed")
                }
            } label: {
                Label(
                    browser.isBlockingSelectedSite
                        ? "Protection on"
                        : "Protection off",
                    systemImage: browser.isBlockingSelectedSite
                        ? "shield.checkered"
                        : "shield.slash"
                )
                .labelStyle(.iconOnly)
            }
            .accessibilityIdentifier("page-menu-protection")
        }
        .font(.body.weight(.semibold))
        .tint(Color.contextInk)
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
    }
}

private struct ReaderView: View {
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
