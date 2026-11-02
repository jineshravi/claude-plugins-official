import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// A single checklist entry.
struct ChecklistItem: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var isDone: Bool = false
}

/// Persists the checklist in the shared App Group container so the app,
/// the widget extension and App Intents all read and write the same file.
enum ChecklistStore {
    /// Must match the App Group configured on both targets.
    static let appGroupID = "group.com.example.lockchecklist"
    static let widgetKind = "LockChecklistWidget"

    private static var fileURL: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("checklist.json")
    }

    static func load() -> [ChecklistItem] {
        guard let data = try? Data(contentsOf: fileURL),
              let items = try? JSONDecoder().decode([ChecklistItem].self, from: data)
        else { return sample }
        return items
    }

    static func save(_ items: [ChecklistItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        // `completeUntilFirstUserAuthentication` keeps the file readable while the
        // device is locked (after the first unlock since boot), which is required
        // for ticking items straight from the Lock Screen.
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        reloadWidgets()
    }

    @discardableResult
    static func toggle(id: String) -> [ChecklistItem] {
        var items = load()
        if let i = items.firstIndex(where: { $0.id == id }) {
            items[i].isDone.toggle()
            save(items)
        }
        return items
    }

    /// Ticks the first unfinished item. Returns its title, if any.
    @discardableResult
    static func tickNext() -> String? {
        var items = load()
        guard let i = items.firstIndex(where: { !$0.isDone }) else { return nil }
        items[i].isDone = true
        save(items)
        return items[i].title
    }

    static func resetAll() {
        save(load().map { var item = $0; item.isDone = false; return item })
    }

    static func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) {
            ControlCenter.shared.reloadAllControls()
        }
        #endif
    }

    static let sample: [ChecklistItem] = [
        ChecklistItem(title: "Take vitamins"),
        ChecklistItem(title: "Drink water"),
        ChecklistItem(title: "Walk 20 min"),
        ChecklistItem(title: "Read 10 pages"),
    ]
}
