import SwiftUI

struct PerformerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: LiveEditorViewModel

    @State private var performerDraft = ""

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.performerSuggestions.isEmpty {
                    Section("performer.suggestions") {
                        ForEach(viewModel.performerSuggestions, id: \.self) { performer in
                            Button {
                                toggle(performer)
                            } label: {
                                HStack {
                                    Text(performer)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if viewModel.performers.contains(performer) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(
                                viewModel.performers.contains(performer) ? .isSelected : []
                            )
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
