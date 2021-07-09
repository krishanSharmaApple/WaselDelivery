//
//  MultiLocationTableViewCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 7/28/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class MultiLocationTableViewCell: UITableViewCell {

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var outletStatusLabel: UILabel!
    @IBOutlet weak var distanceAndCostLabel: UILabel!
    @IBOutlet weak var checkMarkButton: UIButton!
    @IBOutlet weak var locationIconImageView: UIImageView!
    @IBOutlet weak var outletStatusLabelheightConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkMarkButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var addressLabel: UILabel!

    class func nib() -> UINib {
        return UINib(nibName: "MultiLocationTableViewCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "MultiLocationTableViewCell"
    }

    // MARK: - User defined methods

    func loadOutletDetails(_ aOutlet: Outlet, isOutletSelected: Bool, isDuplicatedOutlet: Bool) {
        checkMarkButton.isSelected = isOutletSelected
        
        let outletDetails = aOutlet.loadOutletDetails(aOutlet, isOutletSelected: isOutletSelected, isDuplicatedOutlet: isDuplicatedOutlet)
        addressLabel.text = outletDetails.address_
        addressLabel.isHidden = outletDetails.hideAddressLabel
        locationLabel.text = outletDetails.location_
        distanceAndCostLabel.attributedText = outletDetails.distanceAndCost_
        self.updateLocationAndAddressLabelUI(aOutlet, isOutletSelected: isOutletSelected)
    }
    
    func updateLocationAndAddressLabelUI(_ aOutlet: Outlet, isOutletSelected: Bool) {
        // Hide or grayed out the fields based on outlet status(3:Open, 2:Busy, 1:Closed)
        if 3 == aOutlet.openStatus {
            self.isUserInteractionEnabled = true
            locationLabel.textColor = UIColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 1.0)
            addressLabel.textColor = UIColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 1.0)
            
            let selectedColor = (true == isOutletSelected) ? UIColor(red: 126.0/255.0, green: 197.0/255.0, blue: 134.0/255.0, alpha: 1.0) : UIColor.gray
            locationIconImageView.tintColor = selectedColor
            
            outletStatusLabel.isHidden = true
            outletStatusLabelheightConstraint.constant = 0.0
        } else {
            self.isUserInteractionEnabled = false
            locationLabel.textColor = UIColor(red: 193.0/255.0, green: 193.0/255.0, blue: 193.0/255.0, alpha: 1.0)
            locationIconImageView.tintColor = UIColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 0.5)
            outletStatusLabel.isHidden = false
            addressLabel.textColor = UIColor(red: 193.0/255.0, green: 193.0/255.0, blue: 193.0/255.0, alpha: 1.0)
            
            let outletStatus = Utilities.isOutletOpen(aOutlet)
            var messageString = outletStatus.message
            if 2 == aOutlet.openStatus { // Busy
                messageString = OutletBusyMessage
            }
            outletStatusLabel.text = messageString
            outletStatusLabelheightConstraint.constant = 21.0
        }
    }
    
    // MARK: - IBActions

    @IBAction func checkMarkButtonAction(_ sender: Any) {
        checkMarkButton.isSelected = !checkMarkButton.isSelected
    }
    
}
