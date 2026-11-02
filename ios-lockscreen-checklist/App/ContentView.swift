import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var items: [ChecklistItem] = ChecklistStore.load()
    @State private var newTitle = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add an item", text: $newTitle)
                            .onSubmit(add)
                        Button(action: add) { Image(systemName: "plus.circle.fill") }
                            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                Section {
                    ForEach($items) { $item in
                        Button {
                            item.isDone.toggle()
                            persist()
                        } label: {
                            HStack {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isDone ? .green : .secondary)
                                Text(item.title)
                                    .strikethrough(item.isDone)
                                    .foregroundStyle(item.isDone ? .secondary : .primary)
                            }
                        }
                    }
                    .onDelete { items.remove(atOffsets: $0); persist() }
                    .onMove { items.move(fromOffsets: $0, toOffset: $1); persist() }
                } header: {
                    Text("\(items.filter(\.isDone).count) of \(items.count) done")
                } footer: {
                    Text("Add the “Checklist” widget to your Lock Screen to tick items without opening the app.")
                }
            }
            .navigationTitle("Checklist")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        for i in items.indices { items[i].isDone = false }
                        persist()
                    }
                }
            }
        }
        // Pick up ticks made from the Lock Screen while the app was in the background.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { items = ChecklistStore.load() }
        }
    }

    private func add() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        items.append(ChecklistItem(title: title))
        newTitle = ""
        persist()
    }

    private func persist() { ChecklistStore.save(items) }
}
