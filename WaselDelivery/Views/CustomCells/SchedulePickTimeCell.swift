//
//  SchedulePickTimeCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 6/2/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class SchedulePickTimeCell: UITableViewCell {

    weak var pickupTimeDelegate: SchedulePickUpTimeProtocol?
    @IBOutlet var pickupTimeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        pickupTimeButton.layer.borderColor = UIColor.black.cgColor
        pickupTimeButton.setImage(UIImage.init(named: "clock"), for: .normal)
        pickupTimeButton.sizeToFit()
        pickupTimeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        pickupTimeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        pickupTimeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    }
    
    class func cellIdentifier() -> String {
        return "SchedulePickTimeCell"
    }
    
    @IBAction func pickupTimeButtonAction(_ sender: Any) {
        if let pickupTimeDelegate_ = pickupTimeDelegate {
            pickupTimeDelegate_.showSchedulePickUpTimePicker()
        }
    }
    
    func updatePickUpTimeText() {
        let dateString = Utilities.getSystemDateString(date: Utilities.shared.cart.deliveryDate, "EEE, dd MMM yyyy, hh:mm a")
        if dateString.length > 0 {
            pickupTimeButton.setTitle(dateString, for: .normal)
        } else {
            pickupTimeButton.setTitle(NSLocalizedString("Schedule delivery time", comment: ""), for: .normal)
        }
    }

}
