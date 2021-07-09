//
//  LocationHistoryCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 10/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class LocationHistoryCell: UITableViewCell {
    
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
        
    class func nib() -> UINib {
        return UINib(nibName: "LocationHistoryCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "LocationHistoryCell"
    }
    
    func loadCell(withLocation location: UserLocation) {
        
        var addressComponents = location.getLocationAddressComponents()
        
        if addressComponents.count > 0 {
            titleLabel.text = addressComponents[0]
            if addressComponents.count > 1 {
                subTitleLabel.text = addressComponents[1...addressComponents.count-1].joined(separator: ",")
            } else {
                subTitleLabel.text = titleLabel.text
            }
        }
    }

}
