import AppIntents

/// Toggles one item. Used by the interactive buttons in the Lock Screen / Home Screen widget.
struct ToggleItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Checklist Item"
    static var description = IntentDescription("Ticks or unticks a checklist item.")
    // Allow running without unlocking so a tap on the Lock Screen works immediately.
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static var isDiscoverable: Bool = false

    @Parameter(title: "Item ID")
    var itemID: String

    init() {}
    init(itemID: String) { self.itemID = itemID }

    func perform() async throws -> some IntentResult {
        ChecklistStore.toggle(id: itemID)
        return .result()
    }
}

/// Ticks the next unfinished item. Usable from Shortcuts, Siri, the Action button
/// and (iOS 18+) the Lock Screen control.
struct TickNextItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Tick Next Checklist Item"
    static var description = IntentDescription("Marks the first unfinished checklist item as done.")
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult & ProvidesDialog {
        if let title = ChecklistStore.tickNext() {
            return .result(dialog: "Ticked \(title)")
        }
        return .result(dialog: "Everything is already done")
    }
}

/// Unticks everything (e.g. for a daily routine).
struct ResetChecklistIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Checklist"
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult {
        ChecklistStore.resetAll()
        return .result()
    }
}

struct ChecklistShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: TickNextItemIntent(),
                    phrases: ["Tick next item in \(.applicationName)"],
                    shortTitle: "Tick Next Item",
                    systemImageName: "checkmark.circle")
        AppShortcut(intent: ResetChecklistIntent(),
                    phrases: ["Reset \(.applicationName)"],
                    shortTitle: "Reset Checklist",
                    systemImageName: "arrow.counterclockwise")
    }
}
