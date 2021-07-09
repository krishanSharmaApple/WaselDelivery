//
//  RestaurantViewCell.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 14/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Cosmos

class RestaurantViewCell: UITableViewCell {

    @IBOutlet weak var restaurantImageView: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var restaurantTypeLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    
    @IBOutlet var collection: [UILabel]!
    
    class func nib() -> UINib {
        return UINib(nibName: "RestaurantViewCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "RestaurantViewCell"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        for label in collection {
            label.layer.borderColor = UIColor.unSelectedTextColor().cgColor
        }
    }
    
    func loadCellWithRestaurantDetails(_ restaurant: Outlet) {
        
        // restaurant image
        restaurantImageView.image = UIImage(named: restaurant.imageUrl ?? "restaurant")
        
        // name
        restaurantNameLabel.text = restaurant.name
        ratingView.rating = Double(restaurant.rating ?? 0.0)
        
        // Rating
        ratingLabel.text = String(describing: restaurant.rating ?? 0.0)
        
        // budget
        for (index, label) in collection.enumerated() {
            if index < (restaurant.budget ?? Budget.none).rawValue {
                label.textColor = UIColor.themeColor()
                label.layer.borderColor = UIColor.themeColor().cgColor
            } else {
                label.textColor = .unSelectedTextColor()
                label.layer.borderColor = UIColor.unSelectedTextColor().cgColor
            }
        }
    }
}
