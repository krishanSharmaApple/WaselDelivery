//
//  BottomBorderField.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 07/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class BottomBorderField: UITextField {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func draw(_ rect: CGRect) {
        self.addBottomLineToTextField(textField: self, rect: rect)
    }
    
    private func addBottomLineToTextField(textField: UITextField, rect: CGRect) {
        let border = CALayer()
        let borderWidth = CGFloat(1.0)
        border.borderColor = UIColor(red: 214.0/255.0, green: 213.0/255.0, blue: 213.0/255.0, alpha: 1.0).cgColor
        border.frame = CGRect(x: 0,
                              y: rect.height - borderWidth,
                              width: rect.width,
                              height: 1)
        border.borderWidth = borderWidth
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
    }
}
