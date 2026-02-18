import Cocoa
import FlutterMacOS
import WidgetKit
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        
        let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
        let widgetChannel = FlutterMethodChannel(name: "com.abhishek.pomodoro/widget",
                                                binaryMessenger: controller.engine.binaryMessenger)
        
        widgetChannel.setMethodCallHandler { (call, result) in
            if call.method == "updateWidget" {
                if let args = call.arguments as? [String: Any],
                   let secondsRemaining = args["secondsRemaining"] as? Int,
                   let totalSeconds = args["totalSeconds"] as? Int,
                   let mode = args["mode"] as? String,
                   let isRunning = args["isRunning"] as? Bool {
                    
                    if let defaults = UserDefaults(suiteName: "group.com.abhishek.pomodoro") {
                        // Calculate target end time for native SwiftUI timer smoothness
                        let targetDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
                        
                        defaults.set(secondsRemaining, forKey: "secondsRemaining")
                        defaults.set(totalSeconds, forKey: "totalSeconds")
                        defaults.set(mode, forKey: "mode")
                        defaults.set(isRunning, forKey: "isRunning")
                        defaults.set(targetDate.timeIntervalSince1970, forKey: "targetTimestamp")
                        
                        // Force distinct synchronization
                        let success = defaults.synchronize()
                        print("Widget Update: isRunning=\(isRunning), mode=\(mode), success=\(success)")
                        
                        if #available(macOS 11.0, *) {
                            DispatchQueue.main.async {
                                WidgetCenter.shared.reloadAllTimelines()
                                WidgetCenter.shared.reloadTimelines(ofKind: "TwilightPomodoroWidgetV2")
                                print("WidgetCenter reload called for all timelines and specific kind")
                            }
                        }
                        result(true)
                    } else {
                        print("Error: App Group UserDefaults is nil")
                        result(FlutterError(code: "UNAVAILABLE",
                                          message: "App Group not found",
                                          details: nil))
                    }
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                      message: "Invalid arguments for updateWidget",
                                      details: nil))
                }
            } else if call.method == "getWidgetState" {
                if let defaults = UserDefaults(suiteName: "group.com.abhishek.pomodoro") {
                    let seconds = defaults.integer(forKey: "secondsRemaining")
                    let total = defaults.integer(forKey: "totalSeconds")
                    let mode = defaults.string(forKey: "mode") ?? "Work"
                    let isRunning = defaults.bool(forKey: "isRunning")
                    
                    let data: [String: Any] = [
                        "secondsRemaining": seconds,
                        "totalSeconds": total,
                        "mode": mode,
                        "isRunning": isRunning
                    ]
                    result(data)
                } else {
                    result(nil)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        super.applicationDidFinishLaunching(notification)
    }

    // This allows notifications to be shown even when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 DEBUG: Notification received in foreground: \(notification.request.content.title)")
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
