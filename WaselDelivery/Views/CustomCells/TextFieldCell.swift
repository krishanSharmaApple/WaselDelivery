//
//  TextFieldCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 08/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class TextFieldCell: UITableViewCell {

    @IBOutlet weak var textField: BottomBorderField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder != nil ? textField.placeholder ?? "" : "", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)])
    }
    
    class func nib() -> UINib {
        return UINib(nibName: "TextFieldCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "TextFieldCell"
    }
    
    func loadCell(withText text: String, placeholder placeholderText: String, isSecured secured: Bool = false, keyboardType type: UIKeyboardType = .default) {
        
        textField.keyboardType = type
        textField.isSecureTextEntry = secured
        
        if text.count != 0 {
            textField.text = text
        }
        if placeholderText.count != 0 {
            textField.placeholder = placeholderText
        }
    }
    
}
