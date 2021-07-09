//
//  ManageProfileCell.swift
//  WaselDelivery
//
//  Created by Amarnath on 04/12/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

enum ProfileCellType: Int {
    case profile
    case manageAddress
    case cards
    case offers
    case getInTouch
    case help
    case about
    case legal
    case facebook
    case twitter
    case instagram
}

class ManageProfileCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleImageView: UIImageView!
    
    class func cellIdentifier() -> String {
        return "ManageProfileCell"
    }
    
    func loadCellWithType(type: ProfileCellType) {
        switch type {
            
        case .manageAddress:
            titleLabel.text = "Manage Address"
            titleImageView.image = UIImage(named: "address")
          
        case .cards:
            titleLabel.text = "Manage Cards"
            titleImageView.image = UIImage(named: "manageCards")

        case .offers:
            titleLabel.text = "See Offers"
            titleImageView.image = UIImage(named: "offers")

        case .getInTouch:
            titleLabel.text = "Get in Touch"
            titleImageView.image = UIImage(named: "getintouch")
            
        case .help:
            titleLabel.text = "Help & Support"
            titleImageView.image = UIImage(named: "suport")
            
        case .about:
            titleLabel.text = "About Wasel"
            titleImageView.image = UIImage(named: "aboutWasel")
            
        default:
            titleLabel.text = "Legal"
            titleImageView.image = UIImage(named: "legal")
        }
    }

}
