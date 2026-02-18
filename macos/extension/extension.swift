import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), secondsRemaining: 1500, totalSeconds: 1500, mode: "Work", isRunning: false, targetDate: Date().addingTimeInterval(1500))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let entry = fetchLatestEntry(date: Date(), configuration: configuration)
        return entry
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = fetchLatestEntry(date: Date(), configuration: configuration)
        return Timeline(entries: [entry], policy: .never)
    }

    private func fetchLatestEntry(date: Date, configuration: ConfigurationAppIntent) -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.com.abhishek.pomodoro")
        let seconds = defaults?.integer(forKey: "secondsRemaining") ?? 1500
        let total = defaults?.integer(forKey: "totalSeconds") ?? 1500
        let mode = defaults?.string(forKey: "mode") ?? "Work"
        let isRunning = defaults?.bool(forKey: "isRunning") ?? false
        let targetTimestamp = defaults?.double(forKey: "targetTimestamp") ?? 0
        
        let targetDate: Date
        if targetTimestamp > 0 {
             targetDate = Date(timeIntervalSince1970: targetTimestamp)
        } else {
             targetDate = Date().addingTimeInterval(Double(seconds))
        }
        
        let finalRunning = isRunning && targetDate > Date()
        
        return SimpleEntry(
            date: date,
            configuration: configuration,
            secondsRemaining: seconds,
            totalSeconds: total > 0 ? total : 1500, // Prevent divide by zero
            mode: mode,
            isRunning: finalRunning,
            targetDate: targetDate
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let secondsRemaining: Int
    let totalSeconds: Int
    let mode: String
    let isRunning: Bool
    let targetDate: Date
}

struct PomodoroWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            // Time Display
            if entry.isRunning {
                Text(entry.targetDate, style: .timer)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else {
                Text("\(formatTime(entry.secondsRemaining)) V2")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            
            // Mode Badge
            Text(entry.mode.uppercased())
                .font(.system(size: 10, weight: .black))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.2))
                .foregroundColor(accentColor)
                .cornerRadius(4)
        }
        .containerBackground(.black, for: .widget)
    }

    private var accentColor: Color {
        if entry.mode == "Work" || entry.mode == "Eye Care" {
            return Color.orange
        } else {
            return Color.green
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let m = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", m, sec)
    }
}

struct PomodoroWidget: Widget {
    let kind: String = "TwilightPomodoroWidgetV2"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            PomodoroWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Twilight Simple")
        .description("Track your session without circles.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}
