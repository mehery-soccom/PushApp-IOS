//
//  DeliveryActivityBundle.swift
//  DeliveryActivity
//
//  Created by Pranjal on 15/07/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct DeliveryActivityBundle: WidgetBundle {
    var body: some Widget {
        DeliveryActivity()
        DeliveryActivityControl()
        DeliveryActivityLiveActivity()
    }
}
