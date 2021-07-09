//
//  OrderAnythingCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 14/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderAnythingCell: UITableViewCell {
    
    @IBOutlet weak var orderAnythingButton: UIButton!
    
    class func nib() -> UINib {
        return UINib(nibName: "OrderAnythingCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "OrderAnythingCell"
    }
    
}
