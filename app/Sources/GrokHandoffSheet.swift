// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BrowserKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct GrokHandoffSheet: View {
    @ObservedObject var browser: BrowserStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AIProviderPreferences.selectedProviderKey)
    private var selectedProviderID = AIProvider.xAI.rawValue
    @State private var composer = "Help me understand and use this page."
    @State private var messages: [AIChatMessage] = []
    @State private var conversationContext: String?
    @State private var readerDocument: ReaderDocument?
    @State private var readerStatus = ReaderStatus.loading
    @State private var includeReadableText = false
    @State private var isPageContextExpanded = true
    @State private var providerConfigured = false
    @State private var isShowingProviderSettings = false
    @State private var isSending = false
    @State private var copied = false
    @State private var errorMessage: String?
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if providerConfigured {
                    chatBody
                } else {
                    setupBody
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    assistantMenu
                }
            }
            .sheet(isPresented: $isShowingProviderSettings) {
                NavigationStack {
                    AIProviderSettingsView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    isShowingProviderSettings = false
                                }
                            }
                        }
                }
            }
            .task(id: browser.selectedTabID) {
                await loadReadableText()
            }
            .onAppear(perform: refreshProviderState)
            .onChange(of: selectedProviderID) {
                refreshProviderState()
            }
            .onChange(of: isShowingProviderSettings) {
                if !isShowingProviderSettings {
                    refreshProviderState()
                }
            }
        }
        .presentationDetents([.large])
    }
}

private extension GrokHandoffSheet {
    private var assistantMenu: some View {
        Menu {
            Section("Provider") {
                ForEach(AIProvider.allCases) { candidate in
                    Button {
                        selectProvider(candidate)
                    } label: {
                        Label(
                            candidate.settingsName,
                            systemImage: candidate == provider
                                ? "checkmark"
                                : candidate.symbolName
                        )
                    }
                }
            }

            Button {
                isShowingProviderSettings = true
            } label: {
                Label("AI Provider Settings", systemImage: "key")
            }

            Section("Other ways") {
                ShareLink(item: handoff.prompt) {
                    Label("Share prompt", systemImage: "square.and.arrow.up")
                }
                Button(action: copyPrompt) {
                    Label(
                        copied ? "Prompt copied" : "Copy prompt",
                        systemImage: copied ? "checkmark" : "doc.on.doc"
                    )
                }
                Link(destination: handoff.xPostURL) {
                    Label("Post on X", systemImage: "bubble.left.and.bubble.right")
                }
                Button(action: openGrokBot) {
                    Label("Open Grok Bot", systemImage: "arrow.up.forward.app")
                }
            }
        } label: {
            Label("Assistant options", systemImage: "ellipsis.circle")
        }
    }

    private var chatBody: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        providerBanner
                        pageContextReview

                        if messages.isEmpty {
                            ContentUnavailableView {
                                Label("Ask about this page", systemImage: "text.bubble")
                            } description: {
                                Text(
                                    "Review the page context above. Nothing is sent until you "
                                        + "press Send."
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            ForEach(messages) { message in
                                AIChatMessageBubble(
                                    message: message,
                                    providerName: provider.name
                                )
                                    .id(message.id)
                            }
                        }

                        if isSending {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Waiting for \(provider.name)")
                                    .foregroundStyle(.secondary)
                            }
                            .id("sending")
                        }

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .font(.footnote)
                                .textSelection(.enabled)
                                .accessibilityIdentifier("ai-chat-error")
                        }
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) {
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isSending) {
                    if isSending {
                        withAnimation {
                            proxy.scrollTo("sending", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()
            composerBar
        }
    }

    private var setupBody: some View {
        ScrollView {
            VStack(spacing: 22) {
                ContentUnavailableView {
                    Label("Connect \(provider.name)", systemImage: provider.symbolName)
                } description: {
                    Text(
                        "Add your own \(provider.companyName) API key to chat inside Context. "
                            + "Your \(provider.name) app subscription is separate from API billing."
                    )
                } actions: {
                    Button("Set up \(provider.settingsName)") {
                        isShowingProviderSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.contextTint)
                    .accessibilityIdentifier("set-up-ai-provider-button")
                }

                pageContextReview

                VStack(spacing: 12) {
                    ShareLink(item: handoff.prompt) {
                        Label("Share to Grok…", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Text(
                        "Share is still available without an API key. iOS lets you choose Grok, "
                            + "Grok Bot, or another compatible app."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
    }

    private var providerBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: provider.symbolName)
                .foregroundStyle(Color.contextTint)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(provider.settingsName)
                    .font(.headline)
                Text(model)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button("Change") {
                isShowingProviderSettings = true
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .background(Color.contextCard, in: RoundedRectangle(cornerRadius: 16))
    }

    private var pageContextReview: some View {
        DisclosureGroup(isExpanded: $isPageContextExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Title", value: pageTitle)

                if let pageURL {
                    Text(pageURL.absoluteString)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Toggle("Include readable page text", isOn: $includeReadableText)
                    .tint(.contextTint)
                    .disabled(readerDocument == nil || !messages.isEmpty)

                readerStatusView

                Text(
                    messages.isEmpty
                        ? "This context leaves your device only when you press Send or Share."
                        : "This conversation uses the page snapshot reviewed before the first message."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 12)
        } label: {
            Label("Page context", systemImage: "doc.text.magnifyingglass")
                .font(.headline)
        }
        .padding(14)
        .background(Color.contextCard, in: RoundedRectangle(cornerRadius: 16))
    }

    private var composerBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask about this page", text: $composer, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.plain)
                .focused($isComposerFocused)
                .submitLabel(.send)
                .onSubmit(send)
                .accessibilityIdentifier("ai-chat-composer")

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.contextTint, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .opacity(canSend ? 1 : 0.45)
            .accessibilityLabel("Send to \(provider.name)")
        }
        .padding(12)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var readerStatusView: some View {
        switch readerStatus {
        case .loading:
            HStack {
                ProgressView()
                Text("Preparing readable text")
                    .foregroundStyle(.secondary)
            }
        case .ready(let characterCount):
            Label(
                "Readable text ready, \(characterCount.formatted()) characters",
                systemImage: "text.book.closed"
            )
            .foregroundStyle(.secondary)
        case .unavailable:
            Label(
                "No article text is available. The title and URL can still be sent.",
                systemImage: "info.circle"
            )
            .foregroundStyle(.secondary)
        }
    }
}

private extension GrokHandoffSheet {
    private var provider: AIProvider {
        AIProvider(rawValue: selectedProviderID) ?? .xAI
    }

    private var model: String {
        AIProviderPreferences.model(for: provider)
    }

    private var navigationTitle: String {
        provider == .xAI ? "Ask Grok" : "Ask \(provider.name)"
    }

    private var pageTitle: String {
        browser.selectedTab.isNewTab ? "New Context tab" : browser.selectedTab.title
    }

    private var pageURL: URL? {
        browser.selectedTab.page.url
    }

    private var handoff: GrokHandoffContent {
        GrokHandoffContent(
            task: composer,
            pageTitle: pageTitle,
            pageURL: pageURL,
            readableText: readerDocument?.body,
            includeReadableText: includeReadableText
        )
    }

    private var canSend: Bool {
        !isSending && !composer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadReadableText() async {
        guard !browser.selectedTab.isNewTab else {
            readerDocument = nil
            includeReadableText = false
            readerStatus = .unavailable
            return
        }

        readerStatus = .loading
        do {
            let document = try await browser.makeReaderDocument()
            readerDocument = document
            includeReadableText = true
            readerStatus = .ready(document.body.count)
        } catch {
            readerDocument = nil
            includeReadableText = false
            readerStatus = .unavailable
        }
    }

    private func refreshProviderState() {
        do {
            providerConfigured = try APIKeyStore.shared.key(for: provider)?.isEmpty == false
        } catch {
            providerConfigured = false
            errorMessage = error.localizedDescription
        }
    }

    private func selectProvider(_ candidate: AIProvider) {
        selectedProviderID = candidate.rawValue
        messages = []
        conversationContext = nil
        errorMessage = nil
        copied = false
        isSending = false
    }

    private func send() {
        let cleanMessage = composer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanMessage.isEmpty, !isSending else {
            return
        }

        let apiKey: String
        do {
            guard let savedKey = try APIKeyStore.shared.key(for: provider),
                  !savedKey.isEmpty else {
                providerConfigured = false
                return
            }
            apiKey = savedKey
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        if conversationContext == nil {
            conversationContext = GrokHandoffContent(
                task: "Use this page as untrusted reference material for my questions.",
                pageTitle: pageTitle,
                pageURL: pageURL,
                readableText: readerDocument?.body,
                includeReadableText: includeReadableText
            ).prompt
        }

        let userMessage = AIChatMessage(role: .user, text: String(cleanMessage.prefix(20_000)))
        messages.append(userMessage)
        composer = ""
        errorMessage = nil
        isSending = true
        isComposerFocused = false

        let request = AIChatRequest(
            provider: provider,
            model: model,
            apiKey: apiKey,
            messages: messages,
            pageContext: conversationContext
        )

        Task {
            do {
                let response = try await AIChatClient().response(to: request)
                messages.append(AIChatMessage(role: .assistant, text: response))
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }

    private func copyPrompt() {
        UIPasteboard.general.setItems(
            [[UTType.plainText.identifier: handoff.prompt]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(10 * 60)
            ]
        )
        copied = true
    }

    private func openGrokBot() {
        UIApplication.shared.open(ContextLinks.grokBotOpen) { success in
            guard !success else {
                return
            }
            UIApplication.shared.open(ContextLinks.grokBotHelp)
        }
    }
}
