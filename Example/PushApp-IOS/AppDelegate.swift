import UIKit
import ActivityKit
import UserNotifications
import PushApp_IOS

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print(granted ? "Push notifications granted" : "Push notifications denied")
        }
                
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }
    
    @available(iOS 16.1, *)
        func startLiveActivity(userInfo: [AnyHashable: Any]) {
            // Parse your userInfo into your activity state
            // Example placeholder attributes & content state — adapt this to your model
            let state = DeliveryActivityAttributes.ContentState(
                message1: userInfo["message1"] as? String ?? "",
                message2: userInfo["message2"] as? String ?? "",
                message3: userInfo["message3"] as? String ?? "",
                message1FontSize: userInfo["message1FontSize"] as? Double ?? 14,
                message1FontColorHex: userInfo["message1FontColorHex"] as? String ?? "#000000",
                line1_font_text_styles: userInfo["line1_font_text_styles"] as? [String] ?? [],
                message2FontSize: userInfo["message2FontSize"] as? Double ?? 14,
                message2FontColorHex: userInfo["message2FontColorHex"] as? String ?? "#000000",
                line2_font_text_styles: userInfo["line2_font_text_styles"] as? [String] ?? [],
                message3FontSize: userInfo["message3FontSize"] as? Double ?? 14,
                message3FontColorHex: userInfo["message3FontColorHex"] as? String ?? "#000000",
                line3_font_text_styles: userInfo["line3_font_text_styles"] as? [String] ?? [],
                backgroundColorHex: userInfo["backgroundColorHex"] as? String ?? "#FFFFFF",
                fontColorHex: userInfo["fontColorHex"] as? String ?? "#000000",
                progressColorHex: userInfo["progressColorHex"] as? String ?? "#0000FF",
                fontSize: userInfo["fontSize"] as? Double ?? 14,
                progressPercent: userInfo["progressPercent"] as? Double ?? 0,
                align: userInfo["align"] as? String ?? "left",
                bg_color_gradient: userInfo["bg_color_gradient"] as? String ?? "",
                bg_color_gradient_dir: userInfo["bg_color_gradient_dir"] as? String ?? ""
            )

            do {
                let activity = try Activity<DeliveryActivityAttributes>.request(
                    attributes: DeliveryActivityAttributes(),
                    contentState: state,
                    pushType: .token
                )
                print("Started Live Activity: \(activity.id)")
                
                Task {
                    for await tokenData in activity.pushTokenUpdates {
                        let pushToken = tokenData.map { String(format: "%02x", $0) }.joined()
                        print("Live Activity Push Token: \(pushToken)")
                        // Here you can send the token to your server or callback
                    }
                }
            } catch {
                print("Live Activity start error: \(error)")
            }
        }
        
        func application(_ application: UIApplication,
                         didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                         fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            print("Received silent push:", userInfo)

            if #available(iOS 16.1, *) {
                startLiveActivity(userInfo: userInfo)
            }

            completionHandler(.newData)
        }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = response.notification.request.identifier
        print("Received notification with ID = \(id)")

        completionHandler()
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushApp.shared.handleDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // Called when a notification is delivered to a foreground app
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner, sound, badge even if app is active
        print("Test")
        completionHandler([.banner, .badge, .sound, .list])
    }
}
