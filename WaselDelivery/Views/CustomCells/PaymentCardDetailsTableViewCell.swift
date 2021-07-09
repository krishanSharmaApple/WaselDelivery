//
//  PaymentCardDetailsTableViewCell.swift
//  WaselDelivery
//
//  Created by Purpletalk on 12/11/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class PaymentCardDetailsTableViewCell: UITableViewCell {

    @IBOutlet weak var cardNumberLabel: UILabel!
    @IBOutlet weak var cardTypeImageView: UIImageView!
    @IBOutlet weak var cardSelectedStatusImageView: UIImageView!
    @IBOutlet weak var cardSelectionImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var cardSelectionImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var cardSelectionImageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteButtonTrailingConstraint: NSLayoutConstraint!

    weak var cardUpdationDelegate: CardUpdationDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.isExclusiveTouch = true
        self.bgView.layer.borderWidth = 1.0
        deleteButton.isHidden = false
    }
    
    deinit {
        cardUpdationDelegate = nil
    }
    
    class func nib() -> UINib {
        return UINib(nibName: "PaymentCardDetailsTableViewCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "PaymentCardDetailsTableViewCell"
    }
    
    func loadCardDetails(shouldShowCardSelection: Bool? = false, paymentCard: PaymentCard, isEditMode: Bool? = false) {
        deleteButton.isHidden = !(isEditMode ?? false)
        deleteButtonWidthConstraint.constant = (true == deleteButton.isHidden) ? 0.0 : 30.0
        deleteButtonTrailingConstraint.constant = (true == deleteButton.isHidden) ? 0.0 : 10.0
        let firstDigits_ = paymentCard.first4Digits ?? "XXXX"
        let lastDigits_ = paymentCard.last4Digits ?? "XXXX"

        cardNumberLabel.text = firstDigits_ + " XXXX XXXX " + lastDigits_ //"5678 XXXX XXXX 9012"
        
        if paymentCard.cardBrand?.caseInsensitiveCompare("visa") == .orderedSame {
            cardTypeImageView.image = UIImage.init(named: "visa")
        } else {
            cardTypeImageView.image = UIImage.init(named: "mastercard")
        }

        if true == shouldShowCardSelection {
            cardSelectedStatusImageView.isHidden = false
            cardSelectedStatusImageView.image = UIImage.init(named: "cardSelected")
            cardSelectionImageViewWidthConstraint.constant = 18.0
            cardSelectionImageViewLeadingConstraint.constant = 5.0
            cardSelectionImageViewTrailingConstraint.constant = 10.0
        } else {
            cardSelectionImageViewWidthConstraint.constant = 0.0
            cardSelectionImageViewLeadingConstraint.constant = 0.0
            cardSelectionImageViewTrailingConstraint.constant = 5.0
            cardSelectedStatusImageView.isHidden = true
            cardSelectedStatusImageView.image = UIImage.init(named: "cardSelected")
        }
        
        if true == paymentCard.isDefaultCard {
            self.bgView.layer.borderColor = UIColor.themeColor().cgColor
        } else {
            self.bgView.layer.borderColor = UIColor.unSelectedTextColor().cgColor
        }
    }

// MARK: - IBActions

    @IBAction func deleteButtonAction(_ sender: Any) {
        cardUpdationDelegate?.deleteCard(self)
    }

}

protocol CardUpdationDelegate: class {
    func deleteCard(_ paymentCardDetailsTableViewCell: PaymentCardDetailsTableViewCell)
}
