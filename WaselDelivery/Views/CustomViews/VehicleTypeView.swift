//
//  VehicleTypeView.swift
//  WaselDelivery
//
//  Created by Vali on 23/03/2020.
//  Copyright © 2020 [x]cube Labs. All rights reserved.
//

import UIKit

@IBDesignable
class VehicleTypeView: UIView {

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    var contentView: UIView?
    let nibName = "VehicleTypeView"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        contentView = view
        contentView?.layer.cornerRadius = 4.0
        contentView?.layer.borderWidth = 1.0
        selectVehicle(false)
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    func selectVehicle(_ select: Bool) {
        if select {
            contentView?.layer.borderColor = UIColor.themeColor().cgColor
            infoLabel?.textColor = UIColor.selectedColor()
        } else {
            contentView?.layer.borderColor = UIColor.unSelectedTextColor().cgColor
            infoLabel?.textColor = UIColor.unSelectedColor()
        }
    }
    
    func setText(text: String) {
        infoLabel?.text = text
    }
    
    func setImage(image: String) {
        imageView?.image = UIImage(named: image)
    }

}
