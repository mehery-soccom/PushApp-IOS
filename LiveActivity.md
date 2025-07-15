# Live Activity Integration for PushApp SDK

This document guides you through adding **Live Activity** support to your iOS app using the PushApp SDK.

---

## Step 1: Add a Widget Target

- In Xcode, add a new **Widget Extension** target to your project.
- Name the widget **DeliveryActivity**.

---

## Step 2: Add the Live Activity Code

- Replace the contents of the new widget's main Swift file (e.g., `DeliveryActivityLiveActivity.swift`) with the following code:

```swift
import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Attributes

struct DeliveryActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var message1: String
        var message2: String
        var message3: String
        
        var message1FontSize: Double
        var message1FontColorHex: String
        var line1_font_text_styles: [String]
        
        var message2FontSize: Double
        var message2FontColorHex: String
        var line2_font_text_styles: [String]
        
        var message3FontSize: Double
        var message3FontColorHex: String
        var line3_font_text_styles: [String]

        var backgroundColorHex: String
        var fontColorHex: String
        var progressColorHex: String
        var fontSize: Double
        
        var progressPercent: Double
        var align : String
        var bg_color_gradient : String
        var bg_color_gradient_dir : String
        var imageFileName: String?
    }
}

// MARK: - Live Activity Widget
@available(iOS 16.2, *)
struct DeliveryActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeliveryActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(context.state.message1)
                        .font(.system(size: context.state.message1FontSize, weight: context.state.line1_font_text_styles.contains("bold") ? .bold : .regular, design: context.state.line1_font_text_styles.contains("italic") ? .serif : .default))
                        .foregroundColor(colorFromHex(context.state.message1FontColorHex))
                        .modifier(TextStyleModifier(styles: context.state.line1_font_text_styles))

                    Text(context.state.message2)
                        .font(.system(size: context.state.message2FontSize, weight: context.state.line2_font_text_styles.contains("bold") ? .bold : .regular, design: context.state.line2_font_text_styles.contains("italic") ? .serif : .default))
                        .foregroundColor(colorFromHex(context.state.message2FontColorHex))
                        .modifier(TextStyleModifier(styles: context.state.line2_font_text_styles))

                    Text(context.state.message3)
                        .font(.system(size: context.state.message3FontSize, weight: context.state.line3_font_text_styles.contains("bold") ? .bold : .regular, design: context.state.line3_font_text_styles.contains("italic") ? .serif : .default))
                        .foregroundColor(colorFromHex(context.state.message3FontColorHex))
                        .modifier(TextStyleModifier(styles: context.state.line3_font_text_styles))

                    ProgressView(value: context.state.progressPercent)
                        .progressViewStyle(LinearProgressViewStyle(tint: colorFromHex(context.state.progressColorHex)))
                        .frame(height: 6)
                        .clipShape(Capsule())
                }

                Spacer()

                if let imageFileName = context.state.imageFileName,
                   let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mehery.ios.sdk") {
                    let imageURL = containerURL.appendingPathComponent(imageFileName)
                    if let uiImage = UIImage(contentsOfFile: imageURL.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                    } else {
                        Text("Image not found")
                    }
                }
            }
            .padding()
            .background(
                backgroundView(for: context.state)
            )
            .activityBackgroundTint(colorFromHex(context.state.backgroundColorHex))
            .activitySystemActionForegroundColor(colorFromHex(context.state.fontColorHex))
            .environment(\.layoutDirection, context.state.align == "right" ? .rightToLeft : .leftToRight)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "shippingbox")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progressPercent * 100))%")
                        .font(.system(size: context.state.fontSize))
                        .bold()
                        .foregroundColor(colorFromHex(context.state.fontColorHex))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading) {
                        Text(context.state.message1)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("Progress: \(Int(context.state.progressPercent * 100))%")
                            .bold()
                            .foregroundColor(colorFromHex(context.state.fontColorHex))
                    }
                }
            } compactLeading: {
                Text("Progress")
                    .font(.caption)
                    .foregroundColor(colorFromHex(context.state.fontColorHex))
            } compactTrailing: {
                Text("\(Int(context.state.progressPercent * 100))%")
                    .font(.caption)
                    .foregroundColor(colorFromHex(context.state.fontColorHex))
            } minimal: {
                Image(systemName: "clock")
                    .foregroundColor(colorFromHex(context.state.fontColorHex))
            }
            .keylineTint(colorFromHex(context.state.progressColorHex))
        }
    }
}

// MARK: - Helpers (Add these helper functions and modifiers)

private func backgroundView(for state: DeliveryActivityAttributes.ContentState) -> some View {
    if !state.bg_color_gradient.isEmpty, !state.bg_color_gradient_dir.isEmpty {
        let startColor = colorFromHex(state.backgroundColorHex)
        let endColor = colorFromHex(state.bg_color_gradient)
        let (startPoint, endPoint) = gradientDirection(from: state.bg_color_gradient_dir)

        return AnyView(
            LinearGradient(
                gradient: Gradient(colors: [startColor, endColor]),
                startPoint: startPoint,
                endPoint: endPoint
            )
        )
    } else {
        return AnyView(colorFromHex(state.backgroundColorHex))
    }
}

private func gradientDirection(from dir: String) -> (UnitPoint, UnitPoint) {
    switch dir.lowercased() {
    case "horizontal":
        return (.leading, .trailing)
    case "vertical":
        return (.top, .bottom)
    default:
        return (.top, .bottom) // Default to vertical
    }
}

struct TextStyleModifier: ViewModifier {
    let styles: [String]
    
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            return content
                .underline(styles.contains("underline"))
        } else {
            return content
        }
    }
}

private func colorFromHex(_ hex: String) -> Color {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if hexSanitized.hasPrefix("#") {
        hexSanitized.removeFirst()
    }

    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)

    return Color(
        red: Double((rgb & 0xFF0000) >> 16) / 255,
        green: Double((rgb & 0x00FF00) >> 8) / 255,
        blue: Double(rgb & 0x0000FF) / 255
    )
}
```
## Step 3: Modify Info.plist
 - Add the following keys to your app's Info.plist:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Needed to support live activities and push notifications</string>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>NSUserTrackingUsageDescription</key>
<string>App uses live activities to provide real-time updates.</string>
```

## Step 4: Enable Capabilities
 - In your app target’s Signing & Capabilities tab:
 -- Add Push Notifications
 - Add Background Modes with Remote notifications enabled
 - Add App Groups (if using shared container for images etc.), with the group identifier group.com.example (or your own)

## Step 5: Sending and Updating Live Activities
For instructions to send or update live activities via push notifications, refer to the PushApp API Documentation (replace # with actual URL).

Additional Notes
The widget supports Lock Screen, Banner, and Dynamic Island.
Customize the widget UI by editing the attributes and view code.
Make sure to test on devices with iOS 16.2+ (for Live Activities support).
Use the PushApp SDK’s APIs to trigger live activity updates from your server.
