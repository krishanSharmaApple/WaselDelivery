//
//  AddressDescriptionCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 23/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class AddressDescriptionCell: UITableViewCell {

    @IBOutlet weak var addressLabel: UILabel!
    
    class func cellIdentifier() -> String {
        return "AddressDescriptionCell"
    }

}
