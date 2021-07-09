//
//  AddressFieldCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 23/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class AddressFieldCell: UITableViewCell {
    
    @IBOutlet weak var textField: BottomBorderField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder != nil ? textField.placeholder ?? "" : "", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)])
    }
    
    class func cellIdentifier() -> String {
        return "AddressFieldCell"
    }
    
    func loadCell(withText text: String, placeholder placeholderText: String) {
        
        if text.count != 0 {
            textField.text = text
        }
        
        if placeholderText.count != 0 {
            textField.placeholder = placeholderText
        }
    }
}
