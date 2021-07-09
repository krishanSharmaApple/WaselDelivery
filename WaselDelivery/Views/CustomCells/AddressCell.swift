//
//  AddressCell.swift
//  WaselDelivery
//
//  Created by sunanda on 3/8/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class AddressCell: UITableViewCell {

    weak var addressDelegate: AddressProtocol?
    @IBOutlet var addAddressButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addAddressButton.layer.borderColor = UIColor.black.cgColor
    }
    
    class func cellIdentifier() -> String {
        return "AddressCell"
    }
    
    @IBAction func addAddress(_ sender: Any) {
        if let addressDelegate_ = addressDelegate {
            addressDelegate_.showAddress()
        }
    }

}
