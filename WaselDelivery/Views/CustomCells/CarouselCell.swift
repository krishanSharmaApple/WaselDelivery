//
//  CarouselCell.swift
//  WaselDelivery
//
//  Created by sunanda on 3/8/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit
import iCarousel

class CarouselCell: UITableViewCell {

    class func cellIdentifier() -> String {
        return "CarouselCell"
    }
    @IBOutlet var carousel: iCarousel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        carousel.isPagingEnabled = true
        carousel.bounces = false
    }
}
