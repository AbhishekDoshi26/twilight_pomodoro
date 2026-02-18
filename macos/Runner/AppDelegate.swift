import Cocoa
import FlutterMacOS
import WidgetKit

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
        let widgetChannel = FlutterMethodChannel(name: "com.abhishek.pomodoro/widget",
                                                binaryMessenger: controller.engine.binaryMessenger)
        
        widgetChannel.setMethodCallHandler { (call, result) in
            if call.method == "updateWidget" {
                if let args = call.arguments as? [String: Any],
                   let secondsRemaining = args["secondsRemaining"] as? Int,
                   let mode = args["mode"] as? String,
                   let isRunning = args["isRunning"] as? Bool {
                    
                    // Save to shared UserDefaults for the Widget
                    // IMPORTANT: Ensure this matches the App Group in Xcode
                    if let defaults = UserDefaults(suiteName: "group.com.abhishek.pomodoro") {
                        // Calculate target end time for native SwiftUI timer smoothness
                        let targetDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
                        
                        defaults.set(secondsRemaining, forKey: "secondsRemaining")
                        defaults.set(mode, forKey: "mode")
                        defaults.set(isRunning, forKey: "isRunning")
                        defaults.set(targetDate.timeIntervalSince1970, forKey: "targetTimestamp")
                        defaults.synchronize()
                        
                        // Trigger widget refresh
                        WidgetCenter.shared.reloadAllTimelines()
                        result(true)
                    } else {
                        result(FlutterError(code: "UNAVAILABLE",
                                          message: "App Group 'group.com.abhishek.pomodoro' not found. Please enable it in Xcode Capabilities.",
                                          details: nil))
                    }
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                      message: "Invalid arguments for updateWidget",
                                      details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        super.applicationDidFinishLaunching(notification)
    }
}
