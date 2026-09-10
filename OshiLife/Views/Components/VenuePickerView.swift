import MapKit
import SwiftUI

struct VenuePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = VenueSearchService()

    let onSelect: (VenueSelection) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if search.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 64, weight: .ultraLight))
                                .foregroundStyle(EventPresentation.accent)
                                .accessibilityHidden(true)
                            Text("venue.search.prompt.title")
                                .font(.system(.title, design: .serif).weight(.bold))
                            Text("venue.search.prompt.message").foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 24)
                        .journalSurface()
                    } else if search.suggestions.isEmpty, search.errorMessage == nil {
                        ContentUnavailableView.search(text: search.query)
                    } else {
                        JournalHeading(title: "venue.picker.title", symbol: "map")
                        ForEach(Array(search.suggestions.enumerated()), id: \.offset) { _, suggestion in
                            suggestionButton(suggestion)
                                .journalSurface()
                        }
                    }
                }
                .padding(EventPresentation.inset)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(EventPresentation.background)
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
                    .background(EventPresentation.surface, in: .rect(cornerRadius: 16))
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
        .tint(EventPresentation.accent)
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
                    .background(EventPresentation.accent.opacity(0.08), in: .rect(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestion.title).font(.headline).foregroundStyle(.primary)
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.up.right")
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
