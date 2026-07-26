import SwiftUI

struct TicketEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var priceText = ""
    @State private var descriptionText = ""

    let onAdd: (String, Int?, String?) -> Void

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("field.ticket_name", text: $name)
                TextField("field.ticket_price", text: $priceText)
                    .keyboardType(.numberPad)
                TextField("field.ticket_description", text: $descriptionText, axis: .vertical)
                    .lineLimit(1...3)
            }
            .navigationTitle("ticket.add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        onAdd(name, Int(priceText.trimmingCharacters(in: .whitespaces)), descriptionText)
                        dismiss()
                    }
                    .disabled(!canAdd)
                }
            }
        }
    }
}
