import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline

struct ChecklistEntry: TimelineEntry {
    let date: Date
    let items: [ChecklistItem]
}

struct ChecklistProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChecklistEntry {
        ChecklistEntry(date: .now, items: ChecklistStore.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChecklistEntry) -> Void) {
        completion(ChecklistEntry(date: .now, items: ChecklistStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChecklistEntry>) -> Void) {
        // The widget is reloaded explicitly whenever the list changes, so no polling is needed.
        completion(Timeline(entries: [ChecklistEntry(date: .now, items: ChecklistStore.load())], policy: .never))
    }
}

// MARK: - Views

/// One tappable row. Tapping runs `ToggleItemIntent` in the widget process —
/// the app is not opened, so this works directly from the Lock Screen.
struct ItemRow: View {
    let item: ChecklistItem
    var font: Font = .caption

    var body: some View {
        Button(intent: ToggleItemIntent(itemID: item.id)) {
            HStack(spacing: 4) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                Text(item.title)
                    .strikethrough(item.isDone)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .font(font)
            .opacity(item.isDone ? 0.6 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ChecklistWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ChecklistEntry

    private var doneCount: Int { entry.items.filter(\.isDone).count }
    private var pending: [ChecklistItem] { entry.items.filter { !$0.isDone } }

    /// Unfinished items first, then finished ones (so recent ticks stay visible for undo).
    private func visible(_ limit: Int) -> [ChecklistItem] {
        Array((pending + entry.items.filter(\.isDone)).prefix(limit))
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            // Inline widgets aren't interactive; show progress only.
            Label(pending.first.map { "Next: \($0.title)" } ?? "All done",
                  systemImage: "checklist")

        case .accessoryCircular:
            // A single big button that ticks the next item.
            Button(intent: TickNextItemIntent()) {
                Gauge(value: Double(doneCount), in: 0...Double(max(entry.items.count, 1))) {
                    Image(systemName: "checkmark")
                } currentValueLabel: {
                    Text("\(doneCount)/\(entry.items.count)")
                }
                .gaugeStyle(.accessoryCircularCapacity)
            }
            .buttonStyle(.plain)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                if entry.items.isEmpty {
                    Text("No items – open app to add").font(.caption)
                } else if pending.isEmpty {
                    Label("All done!", systemImage: "checkmark.seal.fill").font(.headline)
                    Button(intent: ResetChecklistIntent()) {
                        Text("Tap to reset").font(.caption)
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(visible(3)) { ItemRow(item: $0) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        default:
            // Home Screen sizes.
            let limit = family == .systemLarge ? 10 : 4
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Checklist").font(.headline)
                    Spacer()
                    Text("\(doneCount)/\(entry.items.count)").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(visible(limit)) { ItemRow(item: $0, font: .subheadline) }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Widget

struct ChecklistWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: ChecklistStore.widgetKind, provider: ChecklistProvider()) { entry in
            ChecklistWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Checklist")
        .description("Tick off checklist items right from the Lock Screen.")
        .supportedFamilies([
            .accessoryRectangular, .accessoryCircular, .accessoryInline,
            .systemSmall, .systemMedium, .systemLarge,
        ])
    }
}

// MARK: - Lock Screen control (iOS 18+)

/// A Control that can be placed in the Lock Screen's bottom corners or Control Center.
/// Each tap ticks the next unfinished item.
@available(iOS 18.0, *)
struct TickNextControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "LockChecklistTickNext") {
            ControlWidgetButton(action: TickNextItemIntent()) {
                Label("Tick Next", systemImage: "checklist.checked")
            }
        }
        .displayName("Tick Next Item")
        .description("Marks the next checklist item as done.")
    }
}

@main
struct ChecklistWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChecklistWidget()
        if #available(iOS 18.0, *) {
            TickNextControl()
        }
    }
}
