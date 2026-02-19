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
                        let oldIsRunning = defaults.bool(forKey: "isRunning")
                        let oldTarget = defaults.double(forKey: "targetTimestamp")
                        
                        defaults.set(secondsRemaining, forKey: "secondsRemaining")
                        defaults.set(totalSeconds, forKey: "totalSeconds")
                        defaults.set(mode, forKey: "mode")
                        defaults.set(isRunning, forKey: "isRunning")
                        
                        // STRICT DRIFT PREVENTION:
                        // Only set a new target if:
                        // 1. We just started (wasn't running)
                        // 2. The user manually changed time/mode (drift > 5s)
                        if isRunning {
                            let newTarget = Date().addingTimeInterval(TimeInterval(secondsRemaining)).timeIntervalSince1970
                            if !oldIsRunning || abs(newTarget - oldTarget) > 5.0 {
                                defaults.set(newTarget, forKey: "targetTimestamp")
                            }
                        } else {
                            defaults.set(0, forKey: "targetTimestamp")
                        }
                        
                        defaults.synchronize()
                        
                        if #available(macOS 11.0, *) {
                            DispatchQueue.main.async {
                                WidgetCenter.shared.reloadTimelines(ofKind: "TwilightPomodoroWidgetV5")
                            }
                        }
                        result(true)
                    }
 else {
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
                    let isRunning = defaults.bool(forKey: "isRunning")
                    var seconds = defaults.integer(forKey: "secondsRemaining")
                    let mode = defaults.string(forKey: "mode") ?? "Work"
                    
                    if isRunning {
                        let targetTimestamp = defaults.double(forKey: "targetTimestamp")
                        if targetTimestamp > 0 {
                            let now = Date().timeIntervalSince1970
                            seconds = Int(max(0, targetTimestamp - now))
                        }
                    }
                    
                    let data: [String: Any] = [
                        "secondsRemaining": seconds,
                        "totalSeconds": defaults.integer(forKey: "totalSeconds"),
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
