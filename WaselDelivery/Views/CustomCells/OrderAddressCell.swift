//
//  OrderAddressCell.swift
//  WaselDelivery
//
//  Created by sunanda on 12/5/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderAddressCell: UITableViewCell {

    @IBOutlet weak var addressTypeLabel: UILabel!
    @IBOutlet weak var addressTypeImageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addressTypeImageView.tintColor = UIColor.themeColor()
    }

    class func cellIdentifier() -> String {
        return "OrderAddressCell"
    }

    func loadAddress(_ address: Address?) {
        
        if let address_ = address {
            addressLabel.text = address?.getAddressString()
            
            if let adddressType_ = address_.addressType {
                switch adddressType_ {
                case "HOME":
                    addressTypeImageView.image = UIImage(named: "homeOFF")
                case "OFFICE":
                    addressTypeImageView.image = UIImage(named: "workOFF")
                default:
                    addressTypeImageView.image = UIImage(named: "othersOFF")
                }
                addressTypeLabel.text = adddressType_.capitalized
            }
        }
    }
    
}
