import WidgetKit
import SwiftUI

private let appGroupId = "group.com.ollie.life_os"
private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupId) }

// ── Gym Widget ─────────────────────────────────────────────────────────────────

struct GymEntry: TimelineEntry {
    let date: Date
    let workoutName: String
    let exercises: String
    let hasWorkout: Bool
}

struct GymProvider: TimelineProvider {
    func placeholder(in context: Context) -> GymEntry {
        GymEntry(date: Date(), workoutName: "Push Day", exercises: "Bench · Shoulder Press · Triceps", hasWorkout: true)
    }
    func getSnapshot(in context: Context, completion: @escaping (GymEntry) -> Void) {
        completion(makeEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<GymEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [makeEntry()], policy: .after(next)))
    }
    private func makeEntry() -> GymEntry {
        let name = sharedDefaults?.string(forKey: "gym_workout_name") ?? ""
        let exs  = sharedDefaults?.string(forKey: "gym_exercises") ?? ""
        return GymEntry(date: Date(), workoutName: name.isEmpty ? "No workout today" : name,
                        exercises: exs, hasWorkout: !name.isEmpty)
    }
}

struct GymWidgetView: View {
    var entry: GymEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(hex: 0x161618)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: 0x5B7FA8))
                    Text("GYM")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: 0x5B7FA8))
                        .tracking(1.4)
                    Spacer()
                }
                Text(entry.workoutName)
                    .font(.system(size: family == .systemSmall ? 16 : 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if !entry.exercises.isEmpty {
                    Text(entry.exercises)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(family == .systemSmall ? 2 : 3)
                }
                Spacer()
                if entry.hasWorkout {
                    Text("TAP TO START")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: 0x5B7FA8))
                        .tracking(1.2)
                }
            }
            .padding(14)
        }
        .containerBackground(Color(hex: 0x161618), for: .widget)
    }
}

struct GymWidget: Widget {
    let kind = "GymWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymProvider()) { entry in
            GymWidgetView(entry: entry)
                .widgetURL(URL(string: "lifeos://gym/start"))
        }
        .configurationDisplayName("Today's Workout")
        .description("Shows today's gym workout. Tap to start.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ── Days Left Widget ────────────────────────────────────────────────────────────

struct DaysLeftEntry: TimelineEntry {
    let date: Date
    let daysLeft: Int
    let year: Int
    let progress: Double
}

struct DaysLeftProvider: TimelineProvider {
    func placeholder(in context: Context) -> DaysLeftEntry {
        DaysLeftEntry(date: Date(), daysLeft: 245, year: 2026, progress: 0.33)
    }
    func getSnapshot(in context: Context, completion: @escaping (DaysLeftEntry) -> Void) {
        completion(makeEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DaysLeftEntry>) -> Void) {
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        completion(Timeline(entries: [makeEntry()], policy: .after(midnight)))
    }
    private func makeEntry() -> DaysLeftEntry {
        let now  = Date()
        let cal  = Calendar.current
        let year = cal.component(.year, from: now)
        let start = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let end   = cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        let total = end.timeIntervalSince(start)
        let elapsed = now.timeIntervalSince(start)
        let left = cal.dateComponents([.day], from: now, to: end).day ?? 0
        return DaysLeftEntry(date: now, daysLeft: left, year: year, progress: min(elapsed / total, 1))
    }
}

struct DaysLeftWidgetView: View {
    var entry: DaysLeftEntry

    var body: some View {
        ZStack {
            Color(hex: 0x161618)
            VStack(alignment: .leading, spacing: 4) {
                Text(String(entry.year))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(String(entry.daysLeft))
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                Text("days left")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                        Capsule()
                            .fill(Color(hex: 0x5B7FA8))
                            .frame(width: geo.size.width * entry.progress, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.top, 4)
            }
            .padding(14)
        }
        .containerBackground(Color(hex: 0x161618), for: .widget)
    }
}

struct DaysLeftWidget: Widget {
    let kind = "DaysLeftWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaysLeftProvider()) { entry in
            DaysLeftWidgetView(entry: entry)
        }
        .configurationDisplayName("Days Left")
        .description("Days remaining in the year.")
        .supportedFamilies([.systemSmall])
    }
}

// ── Checklist Widget ────────────────────────────────────────────────────────────

struct ChecklistItem: Identifiable {
    let id: String
    let title: String
    let done: Bool
}

struct ChecklistEntry: TimelineEntry {
    let date: Date
    let items: [ChecklistItem]
}

struct ChecklistProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChecklistEntry {
        ChecklistEntry(date: Date(), items: [
            ChecklistItem(id: "1", title: "Morning walk", done: true),
            ChecklistItem(id: "2", title: "Read", done: false),
            ChecklistItem(id: "3", title: "Meditate", done: false),
        ])
    }
    func getSnapshot(in context: Context, completion: @escaping (ChecklistEntry) -> Void) {
        completion(makeEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ChecklistEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .atEnd))
    }
    private func makeEntry() -> ChecklistEntry {
        guard let json = sharedDefaults?.string(forKey: "checklist_items"),
              let data = json.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return ChecklistEntry(date: Date(), items: []) }
        let items = arr.prefix(5).compactMap { d -> ChecklistItem? in
            guard let title = d["title"] as? String, let id = d["id"] as? String else { return nil }
            return ChecklistItem(id: id, title: title, done: d["done"] as? Bool ?? false)
        }
        return ChecklistEntry(date: Date(), items: Array(items))
    }
}

struct ChecklistWidgetView: View {
    var entry: ChecklistEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(hex: 0x161618)
            VStack(alignment: .leading, spacing: 0) {
                Text("TODAY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .tracking(1.4)
                    .padding(.bottom, 10)

                if entry.items.isEmpty {
                    Text("Nothing yet")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.3))
                } else {
                    ForEach(entry.items) { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 13))
                                .foregroundColor(item.done ? Color(hex: 0x5B7FA8) : .white.opacity(0.2))
                            Text(item.title)
                                .font(.system(size: 13))
                                .foregroundColor(item.done ? .white.opacity(0.3) : .white.opacity(0.85))
                                .strikethrough(item.done, color: .white.opacity(0.2))
                                .lineLimit(1)
                        }
                        .padding(.bottom, 7)
                    }
                }
                Spacer()
            }
            .padding(14)
        }
        .containerBackground(Color(hex: 0x161618), for: .widget)
    }
}

struct ChecklistWidget: Widget {
    let kind = "ChecklistWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChecklistProvider()) { entry in
            ChecklistWidgetView(entry: entry)
                .widgetURL(URL(string: "lifeos://checklist"))
        }
        .configurationDisplayName("Today's Checklist")
        .description("Today's checklist at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ── Widget Bundle ───────────────────────────────────────────────────────────────

@main
struct LifeOSWidgetBundle: WidgetBundle {
    var body: some Widget {
        GymWidget()
        DaysLeftWidget()
        ChecklistWidget()
    }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255
        )
    }
}
