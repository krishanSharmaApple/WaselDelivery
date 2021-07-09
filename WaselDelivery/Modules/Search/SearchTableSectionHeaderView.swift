//
//  SearchTableSectionHeaderView.swift
//  WaselDelivery
//
//  Created by Karthik on 28/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

protocol SearchTableSectionHeaderViewDelegate: class {
    func didSelectClearButton(cell: SearchTableSectionHeaderView)
}

class SearchTableSectionHeaderView: UIView {
    
    weak var delegate: SearchTableSectionHeaderViewDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var aButton: UIButton!
    
    class func loadFromNib() -> UIView {
        return UINib(nibName: "SearchTableSectionHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? UIView ?? UIView()
    }

    @IBAction func buttonAction(_ sender: UIButton) {
        delegate?.didSelectClearButton(cell: self)
    }
}
