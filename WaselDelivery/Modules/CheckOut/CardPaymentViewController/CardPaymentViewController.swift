//
//  CardPaymentViewController.swift
//  WaselDelivery
//
//  Created by Purpletalk on 12/03/08.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift

class CardPaymentViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var addNewCardButton: UIButton!
    @IBOutlet weak var proceedButton: UIButton!
    @IBOutlet weak var saveCardButton: UIButton!
    @IBOutlet weak var cardDetailsTableView: UITableView!
    @IBOutlet weak var warningBgView: UIView!
    @IBOutlet weak var cardDetailsTableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var footerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var addNewCardButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var orLabelHeightConstraint: NSLayoutConstraint!

    private var savedCards_: [PaymentCard]?
    var paymentCardInfo: PaymentCardInfo = PaymentCardInfo()
    var selectedCardIndex = -1
    fileprivate var disposeObj: Disposable?
    fileprivate var disposableBag = DisposeBag()
    weak var payTabsPaymentDelegate: PayTabsPaymentDelegate?
    var orderInfo: [String: Any] = [:]
//    var order_: Order?
    var costStructure = CostStruct()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Utilities.shouldHideTabCenterView(tabBarController, true)
        addNavigationView()
        self.navigationView?.titleLabel.text = "Payment Method"
        navigationView?.editButton.isSelected = false
        view.isExclusiveTouch = true
        self.initializeTableViews()
        continueButtonBottomConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 20.0 : 0.0
        self.fetchSavedCards()
        
        addNewCardButton.clipsToBounds = true
        addNewCardButton.layer.cornerRadius = 4.0
        addNewCardButton.layer.borderWidth = 1.0
        addNewCardButton.layer.borderColor = UIColor.unSelectedColor().cgColor
        proceedButton.setTitle("Proceed & Pay BD " + String(format: "%.3f", costStructure.grandTotal), for: .normal)
    }

    override func navigateBack(_ sender: Any?) {
        _ = self.navigationController?.popViewController(animated: true)
    }

    deinit {
        Utilities.log(#function as AnyObject, type: .trace)
    }
    
// MARK: - User defined methods

    func initializeTableViews() {
        self.automaticallyAdjustsScrollViewInsets = false
        self.cardDetailsTableView.contentInset = UIEdgeInsets.zero
        cardDetailsTableView.register(PaymentCardDetailsTableViewCell.nib(), forCellReuseIdentifier: PaymentCardDetailsTableViewCell.cellIdentifier())
        cardDetailsTableViewTopConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
    }
    
// MARK: - UITableViewDelegate & Datasource
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let savedCards = self.savedCards_, 0 < savedCards.count {
            return 71.0
        }
        return 0.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let savedCards = self.savedCards_, 0 < savedCards.count {
            warningBgView.isHidden = true
        } else {
            warningBgView.isHidden = false
            return nil
        }
        let aView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: ScreenWidth, height: 71.0))
        aView.backgroundColor = .white
        let aLabel = UILabel(frame: CGRect(x: 0.0, y: 25.0, width: ScreenWidth - 40.0, height: 21.0))
        aLabel.text = NSLocalizedString("SAVED CARDS", comment: "")
        aLabel.font = UIFont.montserratMediumWithSize(18.0)
        aLabel.textAlignment = .left
        aLabel.textColor = .themeColor()
        aView.addSubview(aLabel)
        return aView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedCards_?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let paymentCards_ = savedCards_, paymentCards_.count > indexPath.row {
            if let paymentCardDetailsTableViewCell = tableView.dequeueReusableCell(withIdentifier: PaymentCardDetailsTableViewCell.cellIdentifier(), for: indexPath) as? PaymentCardDetailsTableViewCell {
                let paymentCard_ = paymentCards_[indexPath.row]
                if true == paymentCard_.isDefaultCard {
                    selectedCardIndex = indexPath.row
                }
                paymentCardDetailsTableViewCell.loadCardDetails(shouldShowCardSelection: paymentCard_.isDefaultCard, paymentCard: paymentCard_)
                return paymentCardDetailsTableViewCell
            } else {
                return UITableViewCell()
            }
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedCardIndex != indexPath.row, -1 < selectedCardIndex {
            if let paymentCards_ = savedCards_, paymentCards_.count > indexPath.row {
                var prevSelectedPaymentCard_ = paymentCards_[selectedCardIndex]
                prevSelectedPaymentCard_.isDefaultCard = false
                self.savedCards_?[selectedCardIndex] = prevSelectedPaymentCard_
                
                selectedCardIndex = indexPath.row
                
                var paymentCard_ = paymentCards_[indexPath.row]
                paymentCard_.isDefaultCard = true
                self.savedCards_?[indexPath.row] = paymentCard_
            }
        } else {
            selectedCardIndex = indexPath.row
            if let paymentCards_ = savedCards_, paymentCards_.count > selectedCardIndex {
                var paymentCard_ = paymentCards_[selectedCardIndex]
                paymentCard_.isDefaultCard = true
                self.savedCards_?[indexPath.row] = paymentCard_
            }
            addNewCardButton.layer.borderColor = UIColor.unSelectedColor().cgColor
        }
        self.cardDetailsTableView.reloadData()
    }

// MARK: - API Methods
    
    private func fetchSavedCards() {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        let requestParams: [String: Any] = ["userId": Utilities.shared.user?.id ?? 0] as [String: Any]
        Utilities.showHUD(to: self.view, "")
        disposeObj = ApiManager.shared.apiService.getSavedCards(requestParams as [String: AnyObject]).subscribe(onNext: { [weak self](savedCards) in
            
            Utilities.hideHUD(from: self?.view)
            debugPrint(savedCards)
            self?.savedCards_ = savedCards
            self?.warningBgView.isHidden = (0 < savedCards.count)
            self?.addNewCardButton.setTitle(NSLocalizedString("PAY WITH NEW CARD", comment: ""), for: .normal)
            self?.footerHeightConstraint.constant = 150.0
            self?.addNewCardButtonTopConstraint.constant = 15.0
            self?.orLabelHeightConstraint.constant = 18.0
            self?.view?.layoutIfNeeded()
            if 0 == savedCards.count {
                self?.addNewCardButton.layer.borderColor = UIColor.themeColor().cgColor
            } else {
                self?.addNewCardButton.layer.borderColor = UIColor.unSelectedColor().cgColor
            }
            self?.cardDetailsTableView.reloadData()
            
            }, onError: { [weak self](error) in
                
                Utilities.hideHUD(from: self?.view)
                if let error_ = error as? ResponseError {
                    if error_.getStatusCodeFromError() == .accessTokenExpire {
                        
                    } else {
                        Utilities.showToastWithMessage(error_.description())
                    }
                } else {
                    Utilities.showToastWithMessage(error.localizedDescription)
                }
        })
        disposeObj?.disposed(by: disposableBag)
    }
    
// MARK: - IBActions

    @IBAction func continueButtonAction(_ sender: Any) {
        if let savedCards = self.savedCards_, 0 < savedCards.count, -1 < selectedCardIndex {
            /*let customerEmailString_ = selectedPaymentCard_.customerEmail ?? ""
            let customerPasswordString_ = selectedPaymentCard_.customerPassword ?? ""
            self.prepareTransaction(tokenString: tokenString_, tokenizedCustomerEmail: customerEmailString_, customerPassword: customerPasswordString_, order_: order_, grandTotal: Float(costStructure.grandTotal), completionHandler: { (isTransactionCompleted) in
                if let orderObj_ = self.order_, true == isTransactionCompleted {
                    self.payTabsPaymentDelegate?.updateTransactionStatus(order_: orderObj_)
                    _ = self.navigationController?.popViewController(animated: true)
                } else {
                    debugPrint("Something went wrong.")
                }
            })*/
            let selectedPaymentCard = savedCards[self.selectedCardIndex]
            placeOrder(orderInfo, card: selectedPaymentCard)
        } else {
            /*let isTokenizationEnabled_ = saveCardButton.isSelected
            self.initiatePayTabsSDK(tokenString: "", customerPassword: "", isTokenization: isTokenizationEnabled_, order_: order_, shouldAddNewCard: true, grandTotal: Float(costStructure.grandTotal), isCheckOutFlow: true, completionHandler: { (isTransactionCompleted) in
                if true == isTransactionCompleted {
                    if let orderObj_ = self.order_, true == isTransactionCompleted {
                        self.payTabsPaymentDelegate?.updateTransactionStatus(order_: orderObj_)
                        _ = self.navigationController?.popViewController(animated: true)
                    } else {
                        debugPrint("Something went wrong.")
                    }
                }
            })
            self.view.addSubview(initialSetupViewController.view)
            self.addChild(initialSetupViewController)
            initialSetupViewController.didMove(toParent: self)*/
            self.addMasterCardFlow { (cards) in
                if cards.count > 0 {
                    var cardObj = cards
                    for i in 0..<cardObj.count {
                        cardObj[i].isDefaultCard = false
                    }
                    self.savedCards_ = cardObj
                    self.selectedCardIndex = cards.count - 1
                    self.savedCards_?[self.selectedCardIndex].isDefaultCard = true
                    self.addNewCardButton.layer.borderColor = UIColor.unSelectedColor().cgColor
                    self.cardDetailsTableView.reloadData()
                }
            }
        }
    }

    @IBAction func saveCardButtonAction(_ sender: Any) {
        saveCardButton.isSelected = true //!saveCardButton.isSelected
    }
    
    @IBAction func addNewCardButtonAction(_ sender: Any) {
        if let savedCards = self.savedCards_, 0 < savedCards.count, -1 < selectedCardIndex {
            var prevSelectedPaymentCard_ = savedCards[selectedCardIndex]
            prevSelectedPaymentCard_.isDefaultCard = false
            self.savedCards_?[selectedCardIndex] = prevSelectedPaymentCard_
            selectedCardIndex = -1
            self.cardDetailsTableView.reloadData()
        }
        addNewCardButton.layer.borderColor = UIColor.themeColor().cgColor
    }
    
    private func placeOrder(_ orderObject: [String: Any], card: PaymentCard) {
        Utilities.showHUD(to: self.view, "Confirming...")
        
        disposeObj = ApiManager.shared.apiService.placeOrder(orderObject as [String: AnyObject]).subscribe(
            onNext: { [weak self] (order) in
                Utilities.hideHUD(from: self?.view)
                    let tokenString_ = card.token ?? ""
                    if let self_ = self, let order_ = order as? Order {
                        let orderObj = order_
                        let orderId = orderObj.id!
                        let transactionId = "trans-\(orderId)-\(Int.random(in: 10000 ..< 20000))"
                        let amount = String(self_.costStructure.grandTotal)
                        self_.makePayment(paymentToken: tokenString_, sessionId: nil, threeDSecureId: nil, orderId: String(orderId), transactionId: transactionId, amount: amount, currency: "BHD") { (success) in
                            if true == success {
                                self_.payTabsPaymentDelegate?.updateTransactionStatus(order_: order_)
                                _ = self_.navigationController?.popViewController(animated: true)
                            } else {
                                debugPrint("Something went wrong.")
                            }
                        }
                    }
            }, onError: { [weak self](error) in
                Utilities.hideHUD(from: self?.view)
                if let error_ = error as? ResponseError {
                    if error_.getStatusCodeFromError() == .accessTokenExpire {
                        
                    } else {
                        Utilities.showToastWithMessage(error_.description(), position: .middle)
                    }
                }
        })
        disposeObj?.disposed(by: disposableBag)
    }
    
}

protocol PayTabsPaymentDelegate: class {
    func updateTransactionStatus(order_: Order)
}
