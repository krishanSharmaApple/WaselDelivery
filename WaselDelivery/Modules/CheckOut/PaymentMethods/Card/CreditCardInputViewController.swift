//
//  CreditCardInputViewController.swift
//  WaselDelivery
//
//  Created by Radu Ursache on 14/05/2019.
//  Copyright © 2019 [x]cube Labs. All rights reserved.
//

import UIKit
import Stripe
import CreditCardForm

class CreditCardInputViewController: UIViewController, STPPaymentCardTextFieldDelegate, UITextFieldDelegate {

    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var creditCardView: CreditCardFormView!
    @IBOutlet weak var creditCardDetailsTextField: STPPaymentCardTextField!
    
    var didInputCCInfoHandler: (([String: String]) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.fullNameTextField.text = Utilities.getUser()?.name ?? ""
        self.creditCardView.cardHolderString = self.fullNameTextField.text!
        self.creditCardDetailsTextField.delegate = self
        self.fullNameTextField.delegate = self
        
        self.continueButton.isHidden = true
    }
    
    @IBAction func continueButtonAction(_ sender: Any) {
        if !creditCardDetailsTextField.isValid {
            
            return
        }
        
        let creditCardInfo = ["name": self.creditCardView.cardHolderString,
                              "number": self.creditCardDetailsTextField.cardNumber!,
                              "year": String(self.creditCardDetailsTextField.expirationYear),
                              "month": String(self.creditCardDetailsTextField.expirationMonth),
                              "cvv": self.creditCardDetailsTextField.cvc!]
        
        self.didInputCCInfoHandler?(creditCardInfo)
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
        creditCardView.paymentCardTextFieldDidChange(cardNumber: textField.cardNumber, expirationYear: UInt(textField.expirationYear), expirationMonth: UInt(textField.expirationMonth), cvc: textField.cvc)
    }
    
    func paymentCardTextFieldDidEndEditingExpiration(_ textField: STPPaymentCardTextField) {
        creditCardView.paymentCardTextFieldDidEndEditingExpiration(expirationYear: UInt(textField.expirationYear))
    }
    
    func paymentCardTextFieldDidBeginEditingCVC(_ textField: STPPaymentCardTextField) {
        creditCardView.paymentCardTextFieldDidBeginEditingCVC()
    }
    
    func paymentCardTextFieldDidEndEditingCVC(_ textField: STPPaymentCardTextField) {
        creditCardView.paymentCardTextFieldDidEndEditingCVC()
        
        self.continueButton.isHidden = false
        
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.creditCardDetailsTextField.becomeFirstResponder()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
           self.creditCardView.cardHolderString = self.fullNameTextField.text!
        }
        
        return true
    }
}
