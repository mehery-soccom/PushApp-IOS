import Foundation
import SwiftUICore
import UIKit
import UserNotifications
import WebKit
import SwiftUI

@available(iOS 15.2, *)
public class PushApp: NSObject {
    public static let shared = PushApp()

    private var serverUrl : String = ""
    private var userId: String?
    private var guestId: String?
    internal var tenant: String = ""
    private var channelId: String = ""
    private var socketManager: WebSocketManager?
    private var inAppDisplay: InAppDisplay?
    private var currentContext: UIViewController?
    internal var sandbox: Bool = false

    private override init() {}

    public func initialize(identifier: String, sandbox: Bool = false) {
        self.sandbox = sandbox
        guard let context = self.topViewController() else {
                print("⚠️ Unable to find top view controller")
                return
            }
        self.currentContext = context
        let parts = identifier.split(separator: "$")
        if parts.count == 2 {
            self.tenant = String(parts[0])
            self.channelId = String(parts[1])
            print(self.tenant)
            print(self.channelId)
        } else {
            print("Invalid identifier format")
        }
        
//        if sandbox {
//            // sandbox: tenant.mehery.com
//            self.serverUrl = "https://\(self.tenant).mehery.com"
//        } else {
//            // production: tenant.mehery.com/pushapp
//            self.serverUrl = "https://\(self.tenant).mehery.com"
//        }
        self.serverUrl = "https://d7b9733c4d6b.ngrok-free.app"
        print("Server URL set to: \(self.serverUrl)")

        self.inAppDisplay = InAppDisplay(context: context)

        if let savedUserId = UserDefaults.standard.string(forKey: "pushapp_user_id") {
            self.userId = savedUserId
            self.sendEvent(eventName: "app_open", eventData: ["channel_id": channelId])
            self.connectSocket()
        } else {
            registerDeviceToken()
        }
        
        registerNotificationCategories()
    }

    private func registerDeviceToken() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    public func handleDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("APNs Token: \(tokenString)")
        sendTokenToServer(platform: "ios", token: tokenString)
    }

    private func sendTokenToServer(platform: String, token: String) {
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else { return }

        var request = URLRequest(url: URL(string: "\(serverUrl)/pushapp/api/register")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "platform": platform,
            "token": token,
            "device_id": deviceId,
            "channel_id": channelId
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Token send failed: \(error?.localizedDescription ?? "No error info")")
                return
            }
            if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let device = responseDict!["device"] as? [String: Any],
               let guest = device["user_id"] as? String {
                self.guestId = guest
                self.sendEvent(eventName: "app_open", eventData: [:])
            }
        }.resume()
    }

    public func login(userId: String) {
        self.userId = userId
        UserDefaults.standard.setValue(userId, forKey: "pushapp_user_id")
        connectSocket()

        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else { return }

        var request = URLRequest(url: URL(string: "\(serverUrl)/pushapp/api/register/user")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "user_id": userId,
            "device_id": deviceId,
            "channel_id": channelId
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request).resume()
    }

    private func connectSocket() {
        guard let id = userId else { return }
        DispatchQueue.main.async {
            self.socketManager = WebSocketManager(userId: id, onMessage: { data in
                self.handleNotification(data)
            })
            self.socketManager?.connect()
        }
    }

    public func sendEvent(eventName: String, eventData: [String: Any]) {
        guard let userIdToUse = userId ?? guestId else { return }
        print("Event Triggered \(eventName)")
        print("Event Data \(eventData)")

        var request = URLRequest(url: URL(string: "\(serverUrl)/pushapp/api/events")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "user_id": userIdToUse,
            "channel_id": channelId,
            "event_name": eventName,
            "event_data": eventData
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request).resume()
    }

    private func handleNotification(_ data: [String: Any]) {
        if let messageType = data["message_type"] as? String, messageType == "rule_triggered",
           let ruleId = data["rule_id"] as? String {
            pollForInApp(ruleId: ruleId)
        } else {
            inAppDisplay?.showInApp(from: data)
        }
    }

    public func pollForInApp(ruleId: String) {
        var request = URLRequest(url: URL(string: "\(serverUrl)/pushapp/api/poll/in-app")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["rule_id": ruleId])

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = response!["success"] as? Bool, success,
               let notificationData = response!["data"] as? [String: Any] {
                DispatchQueue.main.async {
                    self.inAppDisplay?.showInApp(from: notificationData)
                }
            }
        }.resume()
    }
    
    private func registerNotificationCategories() {
        let categoryMap: [(String, [(title: String, id: String)])] = [
            ("CONFIRMATION_CATEGORY", [("Yes", "PUSHAPP_YES"), ("No", "PUSHAPP_NO")]),
            ("RESPONSE_CATEGORY", [("Accept", "PUSHAPP_ACCEPT"), ("Reject", "PUSHAPP_REJECT")]),
            ("SUBSCRIPTION_CATEGORY", [("Subscribe", "PUSHAPP_SUB"), ("Unsubscribe", "PUSHAPP_UNSUB")]),
            ("TRANSACTION_CATEGORY", [("Buy", "PUSHAPP_BUY"), ("Sell", "PUSHAPP_SELL")]),
            ("CONTENT_CATEGORY", [("View", "PUSHAPP_VIEW"), ("Add", "PUSHAPP_ADD")]),
            ("CHECKOUT_CATEGORY", [("Cart", "PUSHAPP_CART"), ("Pay", "PUSHAPP_PAY")]),
            ("FORM_ACTION_CATEGORY", [("Save", "PUSHAPP_SAVE"), ("Submit", "PUSHAPP_SUBMIT")]),
            ("DESTRUCTIVE_ACTION_CATEGORY", [("Cancel", "PUSHAPP_CANCEL"), ("Delete", "PUSHAPP_DELETE")]),
            ("CONTACT_CATEGORY", [("Call", "PUSHAPP_CALL"), ("Email", "PUSHAPP_EMAIL")])
        ]

        var categories: Set<UNNotificationCategory> = []

        for (categoryId, actionsInfo) in categoryMap {
            let actions = actionsInfo.map { info in
                UNNotificationAction(identifier: info.id, title: info.title, options: [.foreground])
            }

            let category = UNNotificationCategory(
                identifier: categoryId,
                actions: actions,
                intentIdentifiers: [],
                options: []
            )
            categories.insert(category)
        }

        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }
    
    private func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        } else if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

// MARK: - WebSocketManager

@available(iOS 15.2, *)
class WebSocketManager: NSObject {
    private let userId: String
    private let onMessage: ([String: Any]) -> Void
    private var webSocketTask: URLSessionWebSocketTask?
    
//    private var url: URL {
//        let baseUrl: String
//        if PushApp.shared.sandbox {
//            baseUrl = "https://\(PushApp.shared.tenant).mehery.com"
//        } else {
//            baseUrl = "https://\(PushApp.shared.tenant).mehery.com"
//        }
//        return URL(string: baseUrl.replacingOccurrences(of: "https", with: "wss") + "/pushapp")!
//    }
    private var url = URL(string: "wss://d7b9733c4d6b.ngrok-free.app/pushapp")!

    init(userId: String, onMessage: @escaping ([String: Any]) -> Void) {
        self.userId = userId
        self.onMessage = onMessage
    }

    @available(iOS 15.2, *)
    func connect() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
        sendAuth()
    }

    private func sendAuth() {
        let authMessage: [String: Any] = [
            "type": "auth",
            "userId": userId
        ]
        if let data = try? JSONSerialization.data(withJSONObject: authMessage) {
            webSocketTask?.send(.data(data)) { error in
                if let error = error {
                    print("Auth error: \(error)")
                }
            }
        }
    }
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("WebSocket Received JSON (data): \(json)")
                            self.onMessage(json)
                        } else {
                            print("Failed to cast JSON from data to [String: Any]")
                        }
                    } catch {
                        print("JSON parsing error from data: \(error.localizedDescription)")
                    }

                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                print("WebSocket Received JSON (string): \(json)")
                                self.onMessage(json)
                            } else {
                                print("Failed to cast JSON from string to [String: Any]")
                            }
                        } catch {
                            print("JSON parsing error from string: \(error.localizedDescription)")
                        }
                    } else {
                        print("Failed to convert string to Data")
                    }

                @unknown default:
                    print("Received unknown WebSocket message type")
                }
                // Continue listening for next message
                self.listen()

            case .failure(let error):
                print("WebSocket receive error: \(error.localizedDescription)")
                // Optionally, you can reconnect or handle error here
            }
        }
    }


}

@available(iOS 15.2, *)
extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        print("WebSocket closed")
    }
}

// MARK: - InAppDisplay

@available(iOS 13.0, *)
class InAppDisplay {
    private weak var context: UIViewController?

    init(context: UIViewController) {
        self.context = context
    }

    @available(iOS 14.0, *)
    func showInApp(from data: [String: Any]) {
        // The 'layout' or type comes from data["type"], not template["layout"]
        guard let dataObject = data["data"] as? NSDictionary, let layout = dataObject["type"] as? String,
              let template = dataObject["template"] as? [String: Any] else {
            print("Invalid in-app data")
            return
        }

        switch layout {
        case "popup":
            showPopup(template)
        case "banner":
            showBanner(template)
        case "pip":
            showPictureInPicture(template)
        default:
            print("Unknown layout type: \(layout)")
        }
    }


    private func showPopup(_ template: [String: Any]) {
        guard let content = (template["data"] as? [String: Any])?["content"] as? [String],
              let html = content.first else { return }

        DispatchQueue.main.async {
            let webView = WKWebView()
            webView.loadHTMLString(html, baseURL: nil)
            webView.translatesAutoresizingMaskIntoConstraints = false

            let vc = UIViewController()
            vc.view.backgroundColor = .black.withAlphaComponent(0.7)
            vc.view.addSubview(webView)

            NSLayoutConstraint.activate([
                webView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
                webView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
                webView.widthAnchor.constraint(equalToConstant: 300),
                webView.heightAnchor.constraint(equalToConstant: 400)
            ])

            let closeBtn = UIButton(type: .custom)
            closeBtn.setTitle("✕", for: .normal)
            closeBtn.addTarget(vc, action: #selector(vc.dismissVC), for: .touchUpInside)
            closeBtn.translatesAutoresizingMaskIntoConstraints = false
            vc.view.addSubview(closeBtn)
            NSLayoutConstraint.activate([
                closeBtn.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 40),
                closeBtn.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20)
            ])

            self.context?.present(vc, animated: true)
        }
    }


    private func showBanner(_ template: [String: Any]) {
        guard let content = (template["data"] as? [String: Any])?["content"] as? [String],
              let html = content.first,
              let context = self.context else { return }
        
        DispatchQueue.main.async {
            let bannerView = WKWebView()
            bannerView.loadHTMLString(html, baseURL: nil)
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            bannerView.layer.cornerRadius = 8
            bannerView.clipsToBounds = true

            context.view.addSubview(bannerView)

            NSLayoutConstraint.activate([
                bannerView.leadingAnchor.constraint(equalTo: context.view.leadingAnchor, constant: 16),
                bannerView.trailingAnchor.constraint(equalTo: context.view.trailingAnchor, constant: -16),
                bannerView.topAnchor.constraint(equalTo: context.view.safeAreaLayoutGuide.topAnchor, constant: 16),
                bannerView.heightAnchor.constraint(equalToConstant: 100)
            ])

            // Close button
            let closeBtn = UIButton(type: .custom)
            closeBtn.setTitle("✕", for: .normal)
            closeBtn.setTitleColor(.black, for: .normal)
            closeBtn.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            closeBtn.layer.cornerRadius = 12
            closeBtn.translatesAutoresizingMaskIntoConstraints = false

            context.view.addSubview(closeBtn)

            NSLayoutConstraint.activate([
                closeBtn.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 8),
                closeBtn.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -8),
                closeBtn.widthAnchor.constraint(equalToConstant: 24),
                closeBtn.heightAnchor.constraint(equalToConstant: 24)
            ])

            closeBtn.addTargetClosure { _ in
                bannerView.removeFromSuperview()
                closeBtn.removeFromSuperview()
            }
        }
    }


    @available(iOS 14.0, *)
    func showPictureInPicture(_ template: [String: Any]) {
        guard let content = (template["data"] as? [String: Any])?["content"] as? [String],
              let html = content.first,
              let context = self.context else { return }

        DispatchQueue.main.async {
            let pipView = WKWebView()
            pipView.loadHTMLString(html, baseURL: nil)
            pipView.translatesAutoresizingMaskIntoConstraints = false
            pipView.layer.cornerRadius = 8
            pipView.clipsToBounds = true

            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = .clear
            container.addSubview(pipView)

            context.view.addSubview(container)

            NSLayoutConstraint.activate([
                container.trailingAnchor.constraint(equalTo: context.view.trailingAnchor, constant: -20),
                container.bottomAnchor.constraint(equalTo: context.view.bottomAnchor, constant: -100),
                container.widthAnchor.constraint(equalToConstant: 200),
                container.heightAnchor.constraint(equalToConstant: 150),

                pipView.topAnchor.constraint(equalTo: container.topAnchor),
                pipView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                pipView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                pipView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            ])

            let expandButton = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let image = UIImage(systemName: "arrow.up.left.and.arrow.down.right", withConfiguration: config)
            expandButton.setImage(image, for: .normal)
            expandButton.tintColor = .white
            expandButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            expandButton.layer.cornerRadius = 15
            expandButton.translatesAutoresizingMaskIntoConstraints = false

            container.addSubview(expandButton)

            NSLayoutConstraint.activate([
                expandButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 5),
                expandButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5),
                expandButton.widthAnchor.constraint(equalToConstant: 30),
                expandButton.heightAnchor.constraint(equalToConstant: 30)
            ])

            expandButton.addAction(UIAction { [weak self] _ in
                container.removeFromSuperview()
                self?.showPopup(template)
            }, for: .touchUpInside)
        }
    }
    
    




}

typealias UIControlTargetClosure = (UIControl) -> ()

class ClosureSleeve {
    let closure: UIControlTargetClosure
    init(_ closure: @escaping UIControlTargetClosure) {
        self.closure = closure
    }
    @objc func invoke(_ sender: UIControl) {
        closure(sender)
    }
}

extension UIControl {
    func addTargetClosure(_ closure: @escaping UIControlTargetClosure) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke(_:)), for: .touchUpInside)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, .OBJC_ASSOCIATION_RETAIN)
    }
}


private extension UIViewController {
    @objc func dismissVC() {
        dismiss(animated: true)
    }
}

@available(iOS 15.2, *)
public struct PageTrackingModifier: SwiftUI.ViewModifier {
   
    let name: String

    @available(iOS 15.2, *)
    public func body(content: Content) -> some View {
        content
            .onAppear {
                PushApp.shared.sendEvent(eventName: "page_open", eventData: ["page": name])
            }
            .onDisappear {
                PushApp.shared.sendEvent(eventName: "page_closed", eventData: ["page": name])
            }
    }
}

@available(iOS 15.2, *)
public extension View {
    func trackPage(name: String) -> some View {
        self.modifier(PageTrackingModifier(name: name))
    }
}
