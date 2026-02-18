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
        return Timeline(entries: [entry], policy: .atEnd)
    }

    private func fetchLatestEntry(date: Date, configuration: ConfigurationAppIntent) -> SimpleEntry {
        let defaults = UserDefaults(suiteName: "group.com.abhishek.pomodoro")
        let seconds = defaults?.integer(forKey: "secondsRemaining") ?? 1500
        let total = defaults?.integer(forKey: "totalSeconds") ?? 1500
        let mode = defaults?.string(forKey: "mode") ?? "Work"
        let isRunning = defaults?.bool(forKey: "isRunning") ?? false
        let targetTimestamp = defaults?.double(forKey: "targetTimestamp") ?? Date().addingTimeInterval(Double(seconds)).timeIntervalSince1970
        
        let targetDate = Date(timeIntervalSince1970: targetTimestamp)
        
        // If the target date is in the past but the app thinks it's still running, 
        // it means the app hasn't updated its state to 'finished' yet.
        // We should show 00:00 instead of counting into negative time.
        let finalRunning = isRunning && targetDate > Date()
        
        return SimpleEntry(
            date: date,
            configuration: configuration,
            secondsRemaining: seconds,
            totalSeconds: total,
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
            HStack {
                Image(systemName: entry.isRunning ? "timer" : "timer.circle")
                    .foregroundColor(colorForMode(entry.mode))
                Text(entry.mode.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
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
            
            if !entry.isRunning && entry.secondsRemaining > 0 {
                Text("PAUSED")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.orange.opacity(0.8))
            } else if !entry.isRunning && entry.secondsRemaining <= 0 {
                Text("FINISHED")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green.opacity(0.8))
            } else {
                ProgressView(value: calculateProgress(), total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: colorForMode(entry.mode)))
                    .frame(width: 80)
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
    
    private func colorForMode(_ mode: String) -> Color {
        if mode == "Work" || mode == "Eye Care" { return .orange }
        return .green
    }
    
    private func calculateProgress() -> Double {
        let total = Double(entry.totalSeconds > 0 ? entry.totalSeconds : 1)
        if entry.isRunning {
            let remaining = entry.targetDate.timeIntervalSinceNow
            return max(0, min(1.0, 1.0 - (remaining / total)))
        } else {
            let remaining = Double(entry.secondsRemaining)
            return max(0, min(1.0, 1.0 - (remaining / total)))
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
