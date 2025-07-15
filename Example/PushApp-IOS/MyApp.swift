//
//  MyApp.swift
//  PushApp-IOS
//
//  Created by Pranjal on 15/07/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import SwiftUI

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    
                    
                    // Request permission and register for APNs
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }
                }
        }
    }
}
