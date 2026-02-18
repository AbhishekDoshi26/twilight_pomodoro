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
        VStack(spacing: 6) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: entry.isRunning ? "timer" : "timer.circle")
                    .font(.system(size: 10, weight: .bold))
                Text(entry.mode.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .kerning(1)
            }
            .foregroundColor(accentColor.opacity(0.9))
            
            // Main Timer Ring with Centered Text
            ZStack {
                // Start from 0 (top) and go clockwise
                Circle()
                    .stroke(lineWidth: 6)
                    .opacity(0.15)
                    .foregroundColor(.white)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(calculateProgress()))
                    .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                    .foregroundColor(accentColor)
                    // -90 degrees usually starts at top (12 o'clock)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.linear(duration: entry.isRunning ? 1.0 : 0.3), value: calculateProgress())
                    
                // Time Center
                VStack(spacing: 2) {
                    if entry.isRunning {
                        Text(entry.targetDate, style: .timer)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                    } else {
                        Text(formatTime(entry.secondsRemaining))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                    }
                    
                    if !entry.isRunning {
                        Text(entry.secondsRemaining > 0 ? "PAUSED" : "DONE")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(entry.secondsRemaining > 0 ? .orange : .green)
                    }
                }
                .foregroundColor(.white)
            }
            .padding(4)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2), // Deep Twilight
                    Color(red: 0.05, green: 0.1, blue: 0.25) // Aurora Blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var accentColor: Color {
        if entry.mode == "Work" || entry.mode == "Eye Care" {
            return Color.orange
        } else {
            return Color.green
        }
    }
    
    private func calculateProgress() -> Double {
        let total = Double(entry.totalSeconds > 0 ? entry.totalSeconds : 1)
        let elapsed: Double
        
        if entry.isRunning {
            let remaining = entry.targetDate.timeIntervalSinceNow
            elapsed = total - max(0, remaining)
        } else {
            elapsed = total - Double(max(0, entry.secondsRemaining))
        }
        
        return max(0, min(1.0, elapsed / total))
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
        .contentMarginsDisabled()
    }
}
