# PushApp iOS SDK

PushApp SDK enables easy integration of push notifications, in-app notifications, event tracking, and live activity support in your iOS apps.
---

## Features

- Device registration and token management
- User login and session handling
- Event tracking with custom event data
- WebSocket-based in-app notification display (popup, banner, PiP)
- Route-based tracking for user navigation
- Live Activity support for iOS 16.2+ (via separate widget)

---

## Installation

Add the SDK to your project using CocoaPods.
```ruby
pod 'PushApp-IOS'
```
---

## Initialization

Initialize the SDK with your tenant and channel identifier:

```swift
PushApp.shared.initialize(identifier: "tenant$channelId")
```

## Handling Device Token
Pass the APNs device token to the SDK:

```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    PushApp.shared.handleDeviceToken(deviceToken)
}
```

## User Login
Register user login for session tracking:

```swift
PushApp.shared.login(userId: "user123")
```

## Sending Custom Events
Send custom events with data:

```swift
PushApp.shared.sendEvent(eventName: "button_click", eventData: ["button": "subscribe"])
```

## Page Tracking

The SDK automatically tracks page navigation changes to help you analyze user behavior across different screens. Ensure you call the following method whenever the user navigates to a new screen:

```swift
PushApp.shared.sendEvent(eventName: "page_view", eventData: ["page_name": "HomeScreen"])
```
Replace "HomeScreen" with the actual screen or route name.
This helps you monitor which pages users visit and in what sequence, enabling better targeting and analytics.

## In-App Notifications
The SDK handles displaying in-app notifications received via WebSocket or polling automatically.
Just make sure the page tracking is enabled for the page where in app notification is to be displayed

## Live Activity Integration
For Live Activity support, please follow the instructions in the [LiveActivity](LiveActivity.md) document.
Info.plist & Capabilities
Add Push Notifications capability.
Add Background Modes with Remote Notifications.
Configure any other permissions as needed (see [LiveActivity](LiveActivity.md) for details).

## Support & Documentation
For API details, advanced configuration, and push notification handling, refer to the official PushApp API documentation.

If you encounter any issues or have questions, please reach out!
