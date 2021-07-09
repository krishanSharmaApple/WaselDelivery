//
//  AddressTypeCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 23/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

protocol AddressTypeCellDelegate: class {
    func addressTypeCell(cell: AddressTypeCell, didSelectAddressType type: String)
}

class AddressTypeCell: UITableViewCell {

    @IBOutlet var buttonsCollection: [UIButton]!
    @IBOutlet var labelsCollection: [UILabel]!
    weak var delegate: AddressTypeCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        for button in buttonsCollection {
            button.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
            button.imageView?.tintColor = UIColor(red: 134.0/255.0, green: 134.0/255.0, blue: 134.0/255.0, alpha: 1.0)
        }
    }

    @IBAction func addressTypeChanged(_ sender: UIButton) {
        
        var addressType: AddressType = .home
        
        for (index, button) in buttonsCollection.enumerated() {
            if sender.tag == index {
                button.layer.borderColor = UIColor.themeColor().cgColor
                button.isSelected = true
                labelsCollection[index].textColor = .black
                addressType = AddressType.fromHashValue(hashValue: index)
                
            } else {
                button.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
                button.isSelected = false
                labelsCollection[index].textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
            }
        }

        if let delegate_ = delegate {
            delegate_.addressTypeCell(cell: self, didSelectAddressType: addressType.rawValue)
        }
        
    }
    
    class func cellIdentifier() -> String {
        return "AddressTypeCell"
    }

}
