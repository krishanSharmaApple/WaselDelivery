//
//  HighlightButton.swift
//  WaselDelivery
//
//  Created by sunanda on 2/1/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class HighlightButton: UIButton {

    @IBInspectable var highlightColor: UIColor?
    @IBInspectable var defaultColor: UIColor?
    
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            setTitle(self.currentTitle, for: .highlighted)
            if newValue {
                backgroundColor = highlightColor
            } else {
                backgroundColor = defaultColor
            }
            super.isHighlighted = newValue
        }
    }
    
}
