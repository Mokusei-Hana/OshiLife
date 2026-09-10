import SwiftUI
import UIKit

struct ManualXImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ManualXImportViewModel()

    let onImport: (PendingShareImport) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    header
                }
                if let suggestion = viewModel.clipboardSuggestion {
                    Section {
                        clipboardSuggestion(suggestion)
                    }
                }
                Section("manual_import.url.label") {
                    TextField("manual_import.url.placeholder", text: $viewModel.urlString, axis: .vertical)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .lineLimit(2...4)
                        .onChange(of: viewModel.urlString) { _, _ in
                            viewModel.errorMessage = nil
                        }

                    if let errorMessage = viewModel.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task {
                            if let draft = await viewModel.importDraft() {
                                onImport(draft)
                            }
                        }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Label("manual_import.action", systemImage: "square.and.arrow.down")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.canImport)
                    .accessibilityIdentifier("manualXImportButton")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("manual_import.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .task {
                viewModel.checkClipboard(text: UIPasteboard.general.string)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "link.badge.plus")
                .font(.largeTitle.weight(.medium))
                .foregroundStyle(.tint)
            Text("manual_import.message")
                .foregroundStyle(.secondary)
        }
    }

    private func clipboardSuggestion(_ url: URL) -> some View {
        Button {
            viewModel.useClipboardSuggestion()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("manual_import.clipboard.title", systemImage: "doc.on.clipboard")
                    .font(.headline)
                Text(url.absoluteString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text("manual_import.clipboard.action")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
