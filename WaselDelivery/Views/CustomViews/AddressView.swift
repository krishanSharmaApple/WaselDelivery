//
//  AddressView.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 16/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class AddressView: UIView {

    @IBOutlet weak var addressView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var checkMark: UIImageView!
    var isSelected: Bool = false {
        willSet {
            if newValue == true {
                addressView.layer.borderColor = UIColor.themeColor().cgColor
                titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                addressLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                checkMark.isHidden = false
            } else {
                addressView.layer.borderColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0).cgColor
                titleLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
                addressLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
                checkMark.isHidden = true
            }
        }
    }
    
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
        isSelected = false
        addressView.layer.borderColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0).cgColor
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let nib = UINib(nibName: "AddressView", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView ?? UIView()
        return view
    }
    
    func loadAddress(with address: Address) {
        self.isSelected = address.castOff
        titleLabel.text = address.addressType ?? ""
        addressLabel.text = address.getAddressString()
    }
    
}
