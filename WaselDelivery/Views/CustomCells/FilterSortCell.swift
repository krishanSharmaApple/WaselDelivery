//
//  FilterSortCell.swift
//  WaselDelivery
//
//  Created by sunanda on 9/27/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class FilterSortCell: UITableViewCell {

    @IBOutlet weak var ratingButton: UIButton!
    weak var delegate: FilterSortCellProtocol?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        ratingButton.layer.borderColor = UIColor.unSelectedBorderColor().cgColor
        ratingButton.setTitleColor(UIColor.unSelectedTextColor(), for: UIControlState())
        ratingButton.setTitleColor(UIColor.themeColor(), for: .selected)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    class func cellIdentifier() -> String {
        return "FilterSortCell"
    }

    class func nib() -> UINib {
        return UINib(nibName: "FilterSortCell", bundle: Bundle.main)
    }
    
    func updateSort(_ isSelected: Bool) {
        ratingButton.isSelected = isSelected
        ratingButton.layer.borderColor = isSelected ? UIColor.themeColor().cgColor : UIColor.unSelectedBorderColor().cgColor
    }
    
    @IBAction func toggleSelection(_ sender: UIButton) {
        
        ratingButton.isSelected = !ratingButton.isSelected
        ratingButton.layer.borderColor = sender.isSelected ? UIColor.themeColor().cgColor : UIColor.unSelectedBorderColor().cgColor
        delegate?.updateFilterDictionaryWithRating(ratingButton.isSelected)
    }

}

protocol FilterSortCellProtocol {
    
    func updateFilterDictionaryWithRating(_ isSelected: Bool)
}
