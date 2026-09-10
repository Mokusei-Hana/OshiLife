import SwiftUI
import UIKit

struct ManualXImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ManualXImportViewModel()
    @FocusState private var urlFocused: Bool

    let onImport: (PendingShareImport) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "link")
                                .font(.largeTitle.weight(.light))
                            Spacer()
                            Image(systemName: "arrow.down.right")
                                .font(.largeTitle.weight(.ultraLight))
                        }
                        .foregroundStyle(Color(red: 1, green: 0.64, blue: 0.48))
                        .accessibilityHidden(true)
                        Text("manual_import.title")
                            .font(.system(.largeTitle, design: .serif).weight(.bold))
                        Text("manual_import.message")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.white)
                    .background(EventPresentation.ink, in: .rect(cornerRadius: 24))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("manual_import.url.label").font(.headline)
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "link").foregroundStyle(.secondary)
                                .padding(.top, 3)
                            TextField("manual_import.url.placeholder", text: $viewModel.urlString, axis: .vertical)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .lineLimit(3...6)
                                .focused($urlFocused)
                                .accessibilityIdentifier("manualImportURLField")
                                .onChange(of: viewModel.urlString) { _, _ in
                                    viewModel.errorMessage = nil
                                }
                        }
                        .padding(20)
                        .background(EventPresentation.background, in: .rect(cornerRadius: 12))
                        if let error = viewModel.errorMessage {
                            InlineNotice(message: error)
                        }
                    }
                    .journalSurface()

                    if let suggestion = viewModel.clipboardSuggestion {
                        EventSection(title: "manual_import.clipboard.title") {
                            Text(suggestion.absoluteString)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                            Button {
                                viewModel.useClipboardSuggestion()
                                urlFocused = false
                            } label: {
                                Label("manual_import.clipboard.action", systemImage: "doc.on.clipboard")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    if viewModel.isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("common.loading").foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(EventPresentation.inset)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(EventPresentation.background)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Button {
                    urlFocused = false
                    Task {
                        if let draft = await viewModel.importDraft() { onImport(draft) }
                    }
                } label: {
                    HStack {
                        Text(viewModel.isLoading ? "common.loading" : "manual_import.action")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .padding(.vertical, 8)
                }
                .buttonStyle(JournalButtonStyle())
                .controlSize(.large)
                .disabled(!viewModel.canImport)
                .accessibilityIdentifier("manualXImportButton")
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(EventPresentation.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .task { viewModel.checkClipboard(text: UIPasteboard.general.string) }
        }
        .tint(EventPresentation.accent)
        .presentationDragIndicator(.visible)
    }
}
