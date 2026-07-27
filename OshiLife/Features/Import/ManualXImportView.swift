import SwiftUI
import UIKit

struct ManualXImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ManualXImportViewModel()

    let onImport: (PendingShareImport) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if let suggestion = viewModel.clipboardSuggestion {
                        clipboardSuggestion(suggestion)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("manual_import.url.label")
                            .font(.headline)
                        TextField("manual_import.url.placeholder", text: $viewModel.urlString, axis: .vertical)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .lineLimit(2...4)
                            .padding(14)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                            .onChange(of: viewModel.urlString) { _, _ in
                                viewModel.errorMessage = nil
                            }

                        if let errorMessage = viewModel.errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }

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
                    .buttonStyle(.glassProminent)
                    .disabled(!viewModel.canImport)
                    .accessibilityIdentifier("manualXImportButton")
                }
                .padding(20)
            }
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 34, weight: .semibold))
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
            .padding(16)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(.accentColor.opacity(0.12)), in: .rect(cornerRadius: 20))
    }
}
