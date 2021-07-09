//
//  UpshotUICustomization.swift
//  WaselDelivery
//
//  Created by ramchandra on 21/02/19.
//  Copyright © 2019 [x]cube Labs. All rights reserved.
//

import Foundation
import Upshot

class UpshotUICustomization: NSObject, BKUIPreferencesDelegate {

    func preferences(for button: UIButton!, of activityType: BKActivityType, andType activityButton: BKActivityButtonType) {
        if activityButton == .skipButton {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let image = UIImage(named: "upshot_close")
                button.setImage(image, for: .normal)
                button.setImage(image, for: .selected)
                button.setImage(image, for: .highlighted)
            }
        }
    }
}
