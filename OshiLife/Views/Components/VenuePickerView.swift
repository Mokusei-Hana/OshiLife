import MapKit
import SwiftUI

struct VenuePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = VenueSearchService()

    let onSelect: (VenueSelection) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if search.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView(
                        "venue.search.prompt.title",
                        systemImage: "mappin.and.ellipse",
                        description: Text("venue.search.prompt.message")
                    )
                } else if search.suggestions.isEmpty, search.errorMessage == nil {
                    ContentUnavailableView.search(text: search.query)
                } else {
                    List {
                        ForEach(Array(search.suggestions.enumerated()), id: \.offset) { _, suggestion in
                            suggestionButton(suggestion)
                        }
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationTitle("venue.picker.title")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search.query, prompt: "venue.search.placeholder")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .overlay {
                if search.isResolving {
                    ProgressView("common.loading")
                        .padding(24)
                        .glassEffect(.regular, in: .rect(cornerRadius: 20))
                }
            }
            .alert("common.error", isPresented: Binding(
                get: { search.errorMessage != nil },
                set: { if !$0 { search.errorMessage = nil } }
            )) {
                Button("common.ok") { search.errorMessage = nil }
            } message: {
                Text(search.errorMessage ?? "")
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func suggestionButton(_ suggestion: MKLocalSearchCompletion) -> some View {
        Button {
            Task {
                if let selection = await search.resolve(suggestion) {
                    onSelect(selection)
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(suggestion.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(search.isResolving)
    }
}
