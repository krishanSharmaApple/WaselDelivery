//
//  OrderAnythingHeaderView.swift
//  WaselDelivery
//
//  Created by Sunanda on 3/1/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class OrderAnythingHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seperatorView: UIView!

    func updateTitle(title: String, shouldShowSeperator: Bool = false) {
        titleLabel.text = title
        seperatorView.isHidden = !shouldShowSeperator
    }
    
    deinit {
        Utilities.log("OrderAnythingHeaderView deinit" as AnyObject, type: .trace)
    }
}
