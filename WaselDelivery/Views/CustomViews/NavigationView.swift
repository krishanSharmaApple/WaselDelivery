//
//  NavigationView.swift
//  WaselDelivery
//
//  Created by sunanda on 9/23/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class NavigationView: UIView {

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    weak var delegate: AnyObject?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.xibSetup()
    }
    
    fileprivate func xibSetup() {
        let view: UIView = loadViewFromNib()
        view.frame = bounds
        addSubview(view)
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let nib = UINib(nibName: "NavigationView", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView ?? UIView()
        shadowView.layer.shadowColor = UIColor.gray.cgColor
        editButton.isExclusiveTouch = true
        backButton.isExclusiveTouch = true
        return view
    }
    
}
