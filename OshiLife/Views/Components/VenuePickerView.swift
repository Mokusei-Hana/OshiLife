import MapKit
import SwiftUI

struct VenuePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = VenueSearchService()

    let onSelect: (VenueSelection) -> Void

    var body: some View {
        NavigationStack {
            List {
                if search.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 18) {
                        Image(systemName: "map")
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        Text("venue.search.prompt.title").font(.title2.bold())
                        Text("venue.search.prompt.message").foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 32)
                    .listRowSeparator(.hidden)
                } else if search.suggestions.isEmpty, search.errorMessage == nil {
                    ContentUnavailableView.search(text: search.query)
                        .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(Array(search.suggestions.enumerated()), id: \.offset) { _, suggestion in
                            suggestionButton(suggestion)
                        }
                    } header: {
                        Label("venue.picker.title", systemImage: "mappin.and.ellipse")
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .contentMargins(.horizontal, 8)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("venue.picker.title")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $search.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "venue.search.placeholder")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if search.isResolving {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("common.loading").font(.subheadline.weight(.medium))
                    }
                    .padding(18)
                    .glassEffect(.regular, in: .capsule)
                    .padding()
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
            HStack(alignment: .top, spacing: 18) {
                Image(systemName: "mappin")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 40, height: 40)
                    .background(Color(uiColor: .secondarySystemBackground), in: .circle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestion.title).font(.headline).foregroundStyle(.primary)
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(search.isResolving)
    }
}
