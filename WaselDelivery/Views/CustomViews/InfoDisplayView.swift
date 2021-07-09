//
//  InfoDisplayView.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 06/10/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

enum InfoDisplayType {
    case outOfBahrain
    case emptyCart
    case emptyOrderHistory
    case loginFromHistory
    case emptyOutlets
    case emptySearch
    case emptyCards
}

class InfoDisplayView: UIView {
    @IBOutlet weak var infoImageView: UIImageView!
    @IBOutlet weak var infoTitleLabel: UILabel!
    @IBOutlet weak var infoDescriptionLabel: UILabel!
    
    override init(frame: CGRect) { // for using InfoDisplayView in code
        super.init(frame: frame)
        self.xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) { // for using InfoDisplayView in IB
        super.init(coder: aDecoder)
        self.xibSetup()
    }
    
    fileprivate func xibSetup() {
        let view: UIView = loadViewFromNib()
        view.frame = bounds
        addSubview(view)
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let nib = UINib(nibName: "InfoDisplayView", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView ?? UIView()
        return view
    }
    
    func loadInfoWithType(_ infoType: InfoDisplayType) {
        switch infoType {
        case .outOfBahrain:
            infoImageView.image = UIImage(named: "outOfBahrain")
            infoTitleLabel.text = NSLocalizedString("We are yet to partner in your location", comment: "") //ComingSoonTitle
            infoDescriptionLabel.text = OutOfBahrainMessage
        case .emptyCart:
            infoImageView.image = UIImage(named: "emptyCart")
            infoTitleLabel.text = EmptyMessageTitle
            infoDescriptionLabel.text = EmptyCartMessage
        case .emptyOrderHistory:
            infoImageView.image = UIImage(named: "emptyOrderHistory")
            infoTitleLabel.text = EmptyMessageTitle
            infoDescriptionLabel.text = EmptyOrderHistoryMessage
        case .loginFromHistory:
            infoImageView.image = UIImage(named: "emptyOrderHistory")
            infoTitleLabel.text = EmptyMessageTitle
            infoDescriptionLabel.text = LoginFromHistoryMessage
        case .emptyOutlets:
            infoImageView.image = UIImage(named: "comingSoon")
            infoTitleLabel.text = ""
            infoDescriptionLabel.text = EmptyOutletsMessage
        case .emptySearch:
            infoImageView.image = UIImage(named: "notFound")
            infoTitleLabel.text = EmptySearchMessageTitle
        case .emptyCards:
            infoImageView.image = UIImage(named: "emptyOrderHistory")
            infoTitleLabel.text = EmptyMessageTitle
            infoDescriptionLabel.text = EmptyCardsMessage
        }
    }
}
