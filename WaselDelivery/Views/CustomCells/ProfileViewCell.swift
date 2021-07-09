//
//  ProfileViewCell.swift
//  WaselDelivery
//
//  Created by Amarnath on 04/12/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import SDWebImage

class ProfileViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!

    class func cellIdentifier() -> String {
        return "ProfileViewCell"
    }
    
    func loadCellData() {
        if let user = Utilities.shared.user {
            nameLabel.text = user.name
            phoneNumberLabel.text = user.mobile ?? ""
            emailLabel.text = user.email ?? ""
            if let imageURL_ = user.imageUrl {
                let image = imageBaseUrl+imageURL_
                UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: { 
                    self.profileImageView.sd_setImage(with: URL(string: image), placeholderImage: UIImage(named: "profile_placeholder"))
                }, completion: nil)
            } else {
                profileImageView.image = UIImage(named: "profile_placeholder")
            }
        }
    }
}
