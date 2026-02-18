import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Twilight Configuration" }
    static var description: IntentDescription { "Tracks your focus sessions." }
}
