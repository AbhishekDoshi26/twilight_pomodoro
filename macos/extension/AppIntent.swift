import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Pomodoro Configuration" }
    static var description: IntentDescription { "Tracks your focus sessions." }
}
