import AppKit
import SwiftUI

@main
struct JobTallyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let popover = NSPopover()
    private var statusItem: NSStatusItem!
    private let tally = DailyTally()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "plus.forwardslash.minus", accessibilityDescription: "Job application tally")
            button.imagePosition = .imageLeading
            button.title = " \(tally.total)"
            button.target = self
            button.action = #selector(togglePopover)
        }

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 340, height: 440)
        popover.contentViewController = NSHostingController(rootView: TallyView(tally: tally))
        tally.onChange = { [weak self] total in self?.statusItem.button?.title = " \(total)" }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown { popover.performClose(nil) }
        else { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY) }
    }
}

@MainActor
final class DailyTally: ObservableObject {
    struct DayCounts: Codable, Equatable {
        var quick = 0
        var long = 0
        var total: Int { quick + long }
    }
    struct HistoryDay: Identifiable {
        let date: String
        let counts: DayCounts
        var id: String { date }
    }

    @Published private(set) var history: [String: DayCounts] = [:]
    var onChange: ((Int) -> Void)?

    private let defaults = UserDefaults.standard
    private let historyKey = "jobTally.history"
    private var today: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }

    init() {
        if let data = defaults.data(forKey: historyKey),
           let saved = try? JSONDecoder().decode([String: DayCounts].self, from: data) {
            history = saved
        } else if let oldDay = defaults.string(forKey: "jobTally.date") {
            // Migrate counts saved by the first version of Job Tally.
            history[oldDay] = DayCounts(
                quick: defaults.integer(forKey: "jobTally.quick"),
                long: defaults.integer(forKey: "jobTally.long")
            )
            saveHistory()
        }
    }

    var todayCounts: DayCounts { history[today] ?? DayCounts() }
    var quick: Int { todayCounts.quick }
    var long: Int { todayCounts.long }
    var total: Int { todayCounts.total }
    var datedHistory: [HistoryDay] {
        history.keys.sorted(by: >).map { HistoryDay(date: $0, counts: history[$0] ?? DayCounts()) }
    }

    func change(_ kind: Kind, by amount: Int) {
        var counts = todayCounts
        switch kind {
        case .quick: counts.quick = max(0, counts.quick + amount)
        case .long: counts.long = max(0, counts.long + amount)
        }
        history[today] = counts
        saveHistory()
        onChange?(total)
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        defaults.set(data, forKey: historyKey)
    }

    enum Kind { case quick, long }
}

struct TallyView: View {
    @ObservedObject var tally: DailyTally

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Applications").font(.system(size: 19, weight: .semibold))
                Spacer()
                Text("TODAY").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.2).foregroundStyle(.secondary)
            }
            Text("\(tally.total) total").font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 3)
                .padding(.bottom, 15)

            counterRow(title: "Quick apply", subtitle: "Fast applications", value: tally.quick, kind: .quick, tint: .blue)
            Divider().padding(.vertical, 10)
            counterRow(title: "Long application", subtitle: "Company career pages", value: tally.long, kind: .long, tint: .orange)

            Divider().padding(.vertical, 12)
            HStack {
                Text("DAILY HISTORY").font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.1).foregroundStyle(.secondary)
                Spacer()
                Text("\(tally.datedHistory.count) days").font(.system(size: 10)).foregroundStyle(.tertiary)
            }.padding(.bottom, 7)

            if tally.datedHistory.isEmpty {
                Text("Your daily totals will appear here.").font(.system(size: 12)).foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(tally.datedHistory) { entry in
                            HStack {
                                Text(historyDate(entry.date)).font(.system(size: 12, weight: .medium)).frame(width: 92, alignment: .leading)
                                Spacer()
                                Text("Quick  \(entry.counts.quick)").foregroundStyle(.blue)
                                Text("Long  \(entry.counts.long)").foregroundStyle(.orange)
                                Text("\(entry.counts.total)").fontWeight(.semibold).frame(width: 28, alignment: .trailing)
                            }
                            .font(.system(size: 11, design: .rounded)).padding(.vertical, 5)
                            Divider()
                        }
                    }
                }.frame(maxHeight: 210)
            }
        }
        .padding(18)
        .frame(width: 340, height: 440, alignment: .topLeading)
        .background(.regularMaterial)
    }

    private func historyDate(_ value: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = .current
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: value) else { return value }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func counterRow(title: String, subtitle: String, value: Int, kind: DailyTally.Kind, tint: Color) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .medium))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Text("\(value)").font(.system(size: 22, weight: .semibold, design: .rounded)).monospacedDigit().frame(minWidth: 28)
            Button { tally.change(kind, by: -1) } label: {
                Image(systemName: "minus").font(.system(size: 12, weight: .semibold)).frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered).controlSize(.small).disabled(value == 0).accessibilityLabel("Remove one \(title.lowercased())")
            Button { tally.change(kind, by: 1) } label: {
                Image(systemName: "plus").font(.system(size: 13, weight: .semibold)).frame(width: 30, height: 30)
            }
            .buttonStyle(.borderedProminent).tint(tint).controlSize(.small).accessibilityLabel("Add one \(title.lowercased())")
        }
    }
}
