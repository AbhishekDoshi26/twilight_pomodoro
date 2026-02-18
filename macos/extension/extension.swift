import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), secondsRemaining: 1500, mode: "Work", isRunning: false, targetDate: Date().addingTimeInterval(1500))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let entry = fetchLatestEntry(date: Date(), configuration: configuration)
        return entry
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = fetchLatestEntry(date: Date(), configuration: configuration)
        // Since we use the native SwiftUI timer style, we don't need frequent reloads.
        // We only reload when the state changes (Start/Pause/Mode Switch).
        return Timeline(entries: [entry], policy: .atEnd)
    }

    private func fetchLatestEntry(date: Date, configuration: ConfigurationAppIntent) -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.com.abhishek.pomodoro")
        let seconds = defaults?.integer(forKey: "secondsRemaining") ?? 1500
        let mode = defaults?.string(forKey: "mode") ?? "Work"
        let isRunning = defaults?.bool(forKey: "isRunning") ?? false
        let targetTimestamp = defaults?.double(forKey: "targetTimestamp") ?? Date().addingTimeInterval(1500).timeIntervalSince1970
        
        return SimpleEntry(
            date: date,
            configuration: configuration,
            secondsRemaining: seconds,
            mode: mode,
            isRunning: isRunning,
            targetDate: Date(timeIntervalSince1970: targetTimestamp)
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let secondsRemaining: Int
    let mode: String
    let isRunning: Bool
    let targetDate: Date
}

struct PomodoroWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: entry.isRunning ? "timer" : "timer.circle")
                    .foregroundColor(entry.mode == "Work" ? .orange : .green)
                Text(entry.mode.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            // Native SwiftUI Timer style (stays smooth even if reloads are throttled)
            if entry.isRunning {
                Text(entry.targetDate, style: .timer)
                    .font(.system(size: 36, weight: .thin, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else {
                Text(formatTime(entry.secondsRemaining))
                    .font(.system(size: 36, weight: .thin, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            if !entry.isRunning {
                Text("PAUSED")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.red.opacity(0.8))
            } else {
                ProgressView(value: Double(entry.secondsRemaining), total: Double(getMaxSeconds(entry.mode)))
                    .progressViewStyle(LinearProgressViewStyle(tint: entry.mode == "Work" ? .orange : .green))
                    .frame(width: 60)
            }
        }
        .containerBackground(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            ),
            for: .widget
        )
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func getMaxSeconds(_ mode: String) -> Int {
        if mode == "Work" { return 25 * 60 }
        if mode == "Short" { return 5 * 60 }
        return 15 * 60
    }
}

struct PomodoroWidget: Widget {
    let kind: String = "PomodoroWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            PomodoroWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Twilight Pomodoro")
        .description("Track your session with the Twilight Pomodoro.")
        .supportedFamilies([.systemSmall])
    }
}
