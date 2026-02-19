import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), secondsRemaining: 1500, mode: "Work", isRunning: false, targetDate: Date().addingTimeInterval(1500))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        fetchLatestEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = fetchLatestEntry(date: Date(), configuration: configuration)
        // Refresh every 10 minutes as a fallback; app-side pushes are primary
        let nextUpdate = Date().addingTimeInterval(600)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchLatestEntry(date: Date, configuration: ConfigurationAppIntent) -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.com.abhishek.pomodoro")
        let seconds = defaults?.integer(forKey: "secondsRemaining") ?? 1500
        let mode = defaults?.string(forKey: "mode") ?? "Work"
        let isRunning = defaults?.bool(forKey: "isRunning") ?? false
        let targetTimestamp = defaults?.double(forKey: "targetTimestamp") ?? 0
        
        var targetDate = Date().addingTimeInterval(Double(seconds))
        if isRunning && targetTimestamp > 0 {
             targetDate = Date(timeIntervalSince1970: targetTimestamp)
        }
        
        return SimpleEntry(
            date: date,
            configuration: configuration,
            secondsRemaining: seconds,
            mode: mode,
            isRunning: isRunning && targetDate > Date(),
            targetDate: targetDate
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
        VStack(alignment: .leading, spacing: 4) {
            // Status Indicator (Rectangular)
            HStack {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 4, height: 12)
                Text(entry.mode.uppercased())
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(accentColor)
                Spacer()
                if entry.isRunning {
                    Text("ACTIVE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Time Display
            if entry.isRunning {
                Text(entry.targetDate, style: .timer)
                    .font(.system(size: 36, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            } else {
                Text(formatTime(entry.secondsRemaining))
                    .font(.system(size: 36, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Version Label (to confirm rewrite)
            Text("V5 FOCUS")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(16)
        .containerBackground(Color(white: 0.05), for: .widget)
    }

    private var accentColor: Color {
        let mode = entry.mode.lowercased()
        if mode.contains("work") {
            return Color.orange
        } else if mode.contains("eye") || mode.contains("break") {
            return Color.cyan
        } else {
            return Color.orange
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
    let kind: String = "TwilightPomodoroWidgetV5"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            PomodoroWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focus Terminal")
        .description("Clean, strictly rectangular timer.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}
