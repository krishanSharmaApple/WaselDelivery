//
//  ItemSectionView.swift
//  WaselDelivery
//
//  Created by sunanda on 9/26/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class ItemSectionView: UITableViewHeaderFooterView {

    var isSelected = false
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var expandCollapseButton: UIButton!
    @IBOutlet weak var headerTitle: UILabel!
    
    weak var delegate: ReloadSectionProtocol?
    
    deinit {
        Utilities.log("deinit ItemSectionView" as AnyObject, type: .trace)
    }
    
    func loadView(_ item: OutletItemSubCategory, index: Int) {
        headerTitle.text = item.name ?? ""
        isSelected = item.isExpanded ?? false
        expandCollapseButton.isSelected = item.isExpanded ?? false
        headerTitle.textColor = (item.isExpanded ?? false) ? UIColor.black : UIColor(red: (152.0/255.0), green: (152.0/255.0), blue: (152.0/255.0), alpha: 1.0)
        expandCollapseButton.tag = index + 1
    }
    
    @IBAction func expandCollapseAction(_ sender: UIButton) {

        sender.isSelected = !sender.isSelected
        if let delegate_ = delegate {
            delegate_.reloadSectionAt(index: expandCollapseButton.tag)
        }
    }
    
}

protocol ReloadSectionProtocol: class {
    func reloadSectionAt(index: Int)
}
