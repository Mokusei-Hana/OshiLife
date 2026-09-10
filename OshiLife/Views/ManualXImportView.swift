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
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 16) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(.largeTitle, design: .rounded).weight(.light))
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        Text("manual_import.title").font(.largeTitle.bold())
                        Text("manual_import.message")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

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
                                .onChange(of: viewModel.urlString) { _, _ in
                                    viewModel.errorMessage = nil
                                }
                        }
                        .padding(20)
                        .background(Color(uiColor: .secondarySystemBackground), in: .rect(cornerRadius: 16))
                        if let error = viewModel.errorMessage {
                            InlineNotice(message: error)
                        }
                    }

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
                .padding(28)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
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
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(!viewModel.canImport)
                .accessibilityIdentifier("manualXImportButton")
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.bar)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .task { viewModel.checkClipboard(text: UIPasteboard.general.string) }
        }
        .presentationDragIndicator(.visible)
    }
}
