import SwiftUI

struct PerformerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LiveEditorViewModel

    @State private var performerDraft = ""
    @State private var showsAllSuggestions = false

    private let collapsedSuggestionLimit = 8

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.performerSuggestions.isEmpty {
                    Section("performer.suggestions") {
                        TagFlowLayout(spacing: 8) {
                            ForEach(visibleSuggestions, id: \.self) { performer in
                                performerButton(performer)
                            }
                        }
                        .padding(.vertical, 4)

                        if showsAllSuggestions
                            || visibleSuggestions.count < viewModel.performerSuggestions.count {
                            Button {
                                showsAllSuggestions.toggle()
                            } label: {
                                if showsAllSuggestions {
                                    Label("performer.show_less", systemImage: "chevron.up")
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Label("performer.show_more", systemImage: "chevron.down")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }

                Section {
                    TextField("performer.add.placeholder", text: $performerDraft)
                        .textContentType(.organizationName)
                        .submitLabel(.done)
                        .onSubmit(addPerformer)

                    Button("performer.add", systemImage: "plus.circle.fill", action: addPerformer)
                        .disabled(
                            performerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                } header: {
                    Text("performer.custom")
                }
            }
            .navigationTitle("field.performers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var visibleSuggestions: [String] {
        guard !showsAllSuggestions else { return viewModel.performerSuggestions }
        return PerformerCatalog.collapsedNames(
            from: viewModel.performerSuggestions,
            selected: Set(viewModel.performers),
            limit: collapsedSuggestionLimit
        )
    }

    private func performerButton(_ performer: String) -> some View {
        let isSelected = viewModel.performers.contains(performer)

        return Button {
            toggle(performer)
        } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                }
                Text(performer)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 180)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(
                isSelected ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.1),
                in: Capsule()
            )
        }
        .frame(minHeight: 44)
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func toggle(_ performer: String) {
        if viewModel.performers.contains(performer) {
            viewModel.removePerformer(performer)
        } else {
            viewModel.addPerformer(performer)
        }
    }

    private func addPerformer() {
        if viewModel.addPerformer(performerDraft) {
            performerDraft = ""
        }
    }
}
