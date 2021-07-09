//
//  PayTabsCardsViewController.swift
//  WaselDelivery
//
//  Created by Purpletalk on 12/8/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift

class PayTabsCardsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, CardUpdationDelegate {
    
    @IBOutlet weak var cardDetailsTableView: UITableView!
    @IBOutlet weak var warningBgView: UIView!
    @IBOutlet weak var addNewCardButton: UIButton!
    @IBOutlet weak var savedCardsSectionHeaderView: UIView!
    @IBOutlet weak var otherCardsSectionHeaderView: UIView!

    @IBOutlet weak var sectionEditButton: UIButton!
    @IBOutlet weak var noSavedCardsWarningLabel: UILabel!

    @IBOutlet weak var otherCardsSectionSubHeaderLabel: UILabel!
    @IBOutlet weak var otherCardsSectionSubHeaderHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var footerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topViewConstraint: NSLayoutConstraint!

    private var savedCards_: [PaymentCard]?
    var paymentCardInfo: PaymentCardInfo = PaymentCardInfo()
    var selectedCardIndex = -1
    fileprivate var disposeObj: Disposable?
    fileprivate var disposableBag = DisposeBag()
    var editMode: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        Utilities.shouldHideTabCenterView(tabBarController, true)
        addNavigationView()
        self.navigationView?.titleLabel.text = NSLocalizedString("Manage Cards", comment: "")
        navigationView?.editButton.isSelected = false
        navigationView?.editButton.isHidden = true
        navigationView?.editButton.setTitle(NSLocalizedString("Edit", comment: ""), for: .normal)

        view.isExclusiveTouch = true
        self.initializeTableViews()
        topViewConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 20.0 : 0.0
        
        addNewCardButton.clipsToBounds = true
        addNewCardButton.layer.cornerRadius = 4.0
        
        sectionEditButton.clipsToBounds = true
        sectionEditButton.layer.cornerRadius = 4.0
        sectionEditButton.layer.borderWidth = 1.0
        sectionEditButton.layer.borderColor = UIColor.clear.cgColor
        sectionEditButton.isHidden = true

        self.fetchSavedCards()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utilities.shouldHideTabCenterView(tabBarController, true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.MANAGE_CARDS_SCREEN)
    }
    
    override func navigateBack(_ sender: Any?) {
        if true == editMode {
            return
        }
        Utilities.shouldHideTabCenterView(tabBarController, false)
        super.navigateBack(nil)
    }
    
    deinit {
        Utilities.log(#function as AnyObject, type: .trace)
    }
    
// MARK: - User defined methods
    
    fileprivate func initializeTableViews() {
        self.automaticallyAdjustsScrollViewInsets = false
        self.cardDetailsTableView.contentInset = UIEdgeInsets.zero
        cardDetailsTableView.register(PaymentCardDetailsTableViewCell.nib(), forCellReuseIdentifier: PaymentCardDetailsTableViewCell.cellIdentifier())
        
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGestureRecognizer(recognizer:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        cardDetailsTableView.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    fileprivate func updateEditButtonUI() {
        sectionEditButton.isHidden = true
        var editStatusImage_ = UIImage(named: "")
        navigationView?.editButton.setImage(editStatusImage_, for: .normal)
        navigationView?.editButton.setImage(editStatusImage_, for: .selected)
        
        if editMode {
            navigationView?.editButton.setTitle(NSLocalizedString("Done", comment: ""), for: .normal)
        } else {
            navigationView?.editButton.setTitle(NSLocalizedString("Edit", comment: ""), for: .normal)
        }
        
        if false == editMode {
            editStatusImage_ = UIImage(named: "edit")
            sectionEditButton.setTitle(NSLocalizedString("", comment: ""), for: .normal)
            sectionEditButton.layer.borderColor = UIColor.clear.cgColor
            sectionEditButton.setImage(editStatusImage_, for: .normal)
        }
        cardDetailsTableView.reloadSections([0, 1], with: .none)
    }
    
// MARK: - Double TapGesture Recognizer

    @objc func handleDoubleTapGestureRecognizer(recognizer: UITapGestureRecognizer) {
        if false == editMode {
            return
        }
        if recognizer.state == UIGestureRecognizer.State.ended {
            let tapLocation = recognizer.location(in: self.cardDetailsTableView)
            if let indexPath = self.cardDetailsTableView.indexPathForRow(at: tapLocation) {
                if selectedCardIndex != indexPath.row, -1 < selectedCardIndex {
                    var rowIndex = 0
                    if let sortedArray = (savedCards_?.filter { $0.isDefaultCard == true }), 0 < sortedArray.count {
                        if 0 == indexPath.section {
                            rowIndex = 0
                        } else {
                            rowIndex = indexPath.row + 1
                        }
                    } else {
                        rowIndex = indexPath.row
                    }
                    
                    if let paymentCards_ = savedCards_, paymentCards_.count > rowIndex {
                        var paymentCard_ = paymentCards_[rowIndex]
                        self.updateSavedCard(cardIndex: rowIndex, completionHandler: { (isCardUpdated) in
                            if true == isCardUpdated {
                                Utilities.showToastWithMessage(NSLocalizedString("Default card updated successfully", comment: ""), position: .middle)
                                var prevSelectedPaymentCard_ = paymentCards_[self.selectedCardIndex]
                                prevSelectedPaymentCard_.isDefaultCard = false
                                self.savedCards_?[self.selectedCardIndex] = prevSelectedPaymentCard_
                                self.selectedCardIndex = rowIndex
                                paymentCard_.isDefaultCard = true
                                self.savedCards_?[rowIndex] = paymentCard_
                                
                                if 0 == self.savedCards_?.count {
                                    self.editButtonAction(self.sectionEditButton)
                                }
                                let defaultCardsCount = self.cardDetailsTableView.numberOfRows(inSection: 0)
                                let cardsCount = self.cardDetailsTableView.numberOfRows(inSection: 1)
                                if 0 == defaultCardsCount || 0 == cardsCount {
                                    self.reloadSavedCards()
                                    return
                                }

                                UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn], animations: { () -> Void in
                                    self.cardDetailsTableView.beginUpdates()
                                    self.cardDetailsTableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: 0))
                                    if let sortedArray = (self.savedCards_?.filter { $0.isDefaultCard == true }), 0 < sortedArray.count {
                                        self.cardDetailsTableView.moveRow(at: IndexPath(row: 0, section: 0), to: IndexPath(row: 0, section: 1))
                                    }
                                    self.cardDetailsTableView.endUpdates()
                                }, completion: { (_: Bool) -> Void in
                                    self.reloadSavedCards()
                                })
                            }
                        })
                    }
                } else {
                    var rowIndex = 0
                    if let sortedArray = (savedCards_?.filter { $0.isDefaultCard == true }), 0 < sortedArray.count {
                        if 0 == indexPath.section {
                            rowIndex = 0
                        } else {
                            rowIndex = indexPath.row + 1
                        }
                    } else {
                        rowIndex = indexPath.row
                    }
                    
                    if let paymentCards_ = savedCards_, paymentCards_.count > rowIndex {
                        var paymentCard_ = paymentCards_[rowIndex]
                        paymentCard_.isDefaultCard = true
                        self.savedCards_?[rowIndex] = paymentCard_
                        
                        self.updateSavedCard(cardIndex: rowIndex, completionHandler: { (isCardUpdated) in
                            if true == isCardUpdated {
                                Utilities.showToastWithMessage(NSLocalizedString("Default card updated successfully", comment: ""), position: .middle)
                                var isDefaultCardExist = false
                                if 0 != indexPath.section {
                                    if let sortedArray = (self.savedCards_?.filter { $0.isDefaultCard == true }), 0 < sortedArray.count {
                                        isDefaultCardExist = true
                                        var paymentCard_ = paymentCards_[0]
                                        paymentCard_.isDefaultCard = false
                                        self.savedCards_?[0] = paymentCard_
                                    }
                                }
                                self.selectedCardIndex = rowIndex
                                paymentCard_.isDefaultCard = true
                                self.savedCards_?[rowIndex] = paymentCard_
                                
                                if 0 == self.savedCards_?.count {
                                    self.editButtonAction(self.sectionEditButton)
                                }
                                let defaultCardsCount = self.cardDetailsTableView.numberOfRows(inSection: 0)
                                let cardsCount = self.cardDetailsTableView.numberOfRows(inSection: 1)
                                if 0 == defaultCardsCount || 0 == cardsCount {
                                    self.reloadSavedCards()
                                    return
                                }

                                UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn], animations: { () -> Void in
                                    self.cardDetailsTableView.beginUpdates()
                                    self.cardDetailsTableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: 0))
                                    if true == isDefaultCardExist {
                                        self.cardDetailsTableView.moveRow(at: IndexPath(row: 0, section: 0), to: IndexPath(row: 0, section: 1))
                                    }
                                    self.cardDetailsTableView.endUpdates()
                                }, completion: { (_: Bool) -> Void in
                                    self.reloadSavedCards()
                                })
                            } else {
                                Utilities.showToastWithMessage(NSLocalizedString("Some thing went wrong..", comment: ""), position: .middle)
                            }
                        })
                    }
                }
            }
        }
    }
    
    func reloadSavedCards() {
        let sortedArray = self.savedCards_?.sorted(by: { ($0.isDefaultCard ?? false).intValue > ($1.isDefaultCard ?? false).intValue })
        self.savedCards_ = sortedArray
        if let savedCards = self.savedCards_, 0 < savedCards.count {
            navigationView?.editButton.isHidden = false
            navigationView?.editButton.setTitle(NSLocalizedString("Edit", comment: ""), for: .normal)
            warningBgView.isHidden = true
        } else {
            warningBgView.isHidden = false
            navigationView?.editButton.isHidden = true
        }
        self.cardDetailsTableView.reloadData()
    }

// MARK: - UITableViewDelegate & Datasource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let savedCards = self.savedCards_, 0 < savedCards.count {
            if 0 == section {
                if let sortedArray = (savedCards_?.filter { $0.isDefaultCard == true }), 0 < sortedArray.count {
                    return 81.0
                }
                return 110.0
            } else {
                if let sortedArray = (savedCards_?.filter { $0.isDefaultCard == false }), 0 < sortedArray.count {
                    return 53.0
                }
                return 0.0
            }
        }
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if 0 == section {
            if let sortedArray = (savedCards_?.filter { $0.isDefaultCard == true }), 0 < sortedArray.count {
                noSavedCardsWarningLabel.isHidden = true
            } else {
                noSavedCardsWarningLabel.isHidden = false
            }
            return savedCardsSectionHeaderView
        } else {
            if false == editMode {
                otherCardsSectionSubHeaderLabel.isHidden = true
                otherCardsSectionSubHeaderHeightConstraint.constant = 2.0
            } else {
                if let sortedArray = (savedCards_?.filter { $0.isDefaultCard == false }), 0 < sortedArray.count {
                    otherCardsSectionSubHeaderLabel.isHidden = false
                    otherCardsSectionSubHeaderHeightConstraint.constant = 18.0
                } else {
                    otherCardsSectionSubHeaderLabel.isHidden = true
                    otherCardsSectionSubHeaderHeightConstraint.constant = 2.0
                }
            }
            return otherCardsSectionHeaderView
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if 0 == section {
            if let sortedArray = (savedCards_?.filter { $0.isDefaultCard == true }), 0 < sortedArray.count {
                return 1
            }
            return 0
        } else if let savedCardsCount_ = savedCards_?.count, 0 < savedCardsCount_ {
            if let sortedArray = (savedCards_?.filter { $0.isDefaultCard == false }), 0 < sortedArray.count {
                return sortedArray.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let paymentCards_ = savedCards_, paymentCards_.count > indexPath.row {
            var rowIndex = 0
            if let sortedArray = (savedCards_?.filter { $0.isDefaultCard == true }), 0 < sortedArray.count {
                if 0 == indexPath.section {
                    rowIndex = 0
                } else {
                    rowIndex = indexPath.row + 1
                }
            } else {
                rowIndex = indexPath.row
            }
            guard let paymentCardDetailsTableViewCell = tableView.dequeueReusableCell(withIdentifier: PaymentCardDetailsTableViewCell.cellIdentifier(), for: indexPath) as? PaymentCardDetailsTableViewCell else {
                return UITableViewCell()
            }
            let paymentCard_ = paymentCards_[rowIndex]
            if true == paymentCard_.isDefaultCard {
                selectedCardIndex = rowIndex
            }
            paymentCardDetailsTableViewCell.cardUpdationDelegate = self
            paymentCardDetailsTableViewCell.loadCardDetails(shouldShowCardSelection: false, paymentCard: paymentCard_, isEditMode: editMode)
            return paymentCardDetailsTableViewCell
        } else {
            return UITableViewCell()
        }
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
            
            let sortedArray = savedCards.sorted(by: { ($0.isDefaultCard ?? false).intValue > ($1.isDefaultCard ?? false).intValue })
            self?.savedCards_ = sortedArray
            self?.warningBgView.isHidden = (0 < sortedArray.count)
            self?.navigationView?.editButton.isHidden = (0 >= sortedArray.count)
            self?.navigationView?.editButton.setTitle(NSLocalizedString("Edit", comment: ""), for: .normal)
            self?.addNewCardButton.setTitle(NSLocalizedString("Add New Card", comment: ""), for: .normal)
            self?.footerHeightConstraint.constant = 112.0
            self?.view?.layoutIfNeeded()
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

    private func updateSavedCard(cardIndex: Int, completionHandler: ((_ isCardUpdated: Bool) -> Void)? = nil) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        if let savedCards = self.savedCards_, 0 < savedCards.count, -1 < cardIndex {
            let selectedPaymentCard_ = savedCards[cardIndex]
            if let selectedPaymentCardId_ = selectedPaymentCard_.id {
                let requestParams: [String: Any] = ["id": selectedPaymentCardId_] as [String: Any]
                Utilities.showHUD(to: self.view, "")
                disposeObj = ApiManager.shared.apiService.updateSavedCard(requestParams as [String: AnyObject]).subscribe(onNext: { [weak self](savedCards) in
                    
                    Utilities.hideHUD(from: self?.view)
                    debugPrint(savedCards)
                    
                    if let acompletionHandler = completionHandler {
                        acompletionHandler(true)
                    }
                    
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
                        if let acompletionHandler = completionHandler {
                            acompletionHandler(false)
                        }
                })
                disposeObj?.disposed(by: disposableBag)
            }
        }
    }
    
    private func deleteSavedCard(cardIndex: Int, completionHandler: ((_ isCardDeleted: Bool) -> Void)? = nil) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        if let savedCards = self.savedCards_, 0 < savedCards.count, -1 < cardIndex {
            let selectedPaymentCard_ = savedCards[cardIndex]
            if let selectedPaymentCardId_ = selectedPaymentCard_.id {
                let requestParams: [String: Any] = ["id": selectedPaymentCardId_] as [String: Any]
                Utilities.showHUD(to: self.view, "")
                disposeObj = ApiManager.shared.apiService.deleteSavedCard(requestParams as [String: AnyObject]).subscribe(onNext: { [weak self](savedCards) in
                    
                    Utilities.hideHUD(from: self?.view)
                    debugPrint(savedCards)

                    if let acompletionHandler = completionHandler {
                        acompletionHandler(true)
                    }

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
                        if let acompletionHandler = completionHandler {
                            acompletionHandler(false)
                        }
                })
                disposeObj?.disposed(by: disposableBag)
            }
        }
    }
    
// MARK: - CardSaving Delegate

    func deleteCard(_ paymentCardDetailsTableViewCell: PaymentCardDetailsTableViewCell) {
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Are you sure?", text: "Do you really want to delete this card from your list?", buttonText: "NO", cancelButtonText: "YES")
        responder.addCancelAction({
            DispatchQueue.main.async(execute: {
                if let indexPath = self.cardDetailsTableView.indexPath(for: paymentCardDetailsTableViewCell) {
                    var rowIndex = 0
                    if let sortedArray = (self.savedCards_?.filter { $0.isDefaultCard == true }), 0 < sortedArray.count {
                        if 0 == indexPath.section {
                            rowIndex = 0
                        } else {
                            rowIndex = indexPath.row + 1
                        }
                    } else {
                        rowIndex = indexPath.row
                    }
                    
                    if let paymentCards_ = self.savedCards_, paymentCards_.count > rowIndex {
                        self.deleteSavedCard(cardIndex: rowIndex, completionHandler: { (isCardDeleted) in
                            if true == isCardDeleted {
                                Utilities.showToastWithMessage(NSLocalizedString("Card has been deleted successfully", comment: ""), position: .middle)
                                self.savedCards_?.remove(at: rowIndex)
                                if 0 == self.savedCards_?.count {
                                    self.editButtonAction(self.sectionEditButton)
                                }
                                self.reloadSavedCards()
                            }
                        })
                    }
                }
            })
        })
    }
    
// MARK: - IBActions

    @IBAction func saveCardButtonAction(_ sender: Any) {
        // Save card here
    }
    
    @IBAction func addNewCardButtonAction(_ sender: Any) {
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: NSLocalizedString("For verification purpose a refundable amount of .100 fils may be charged on your credit card.", comment: ""), buttonText: "NO", cancelButtonText: "YES")
        responder.addCancelAction({
            /*self.initiatePayTabsSDK(tokenString: "", customerPassword: "", isTokenization: true, completionHandler: { (isTransactionCompleted) in
                if true == isTransactionCompleted {
                    UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CARD_ADDED_EVENT, params: nil)
                    
                    Utilities.showToastWithMessage("Card has been added successfully", position: .middle)
                    self.fetchSavedCards()
                }
            })*/
            self.addMasterCardFlow { (cards) in
                UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CARD_ADDED_EVENT, params: nil)

                Utilities.showToastWithMessage("Card has been added successfully", position: .middle)
                self.fetchSavedCards()
            }
//            self.view.addSubview(self.initialSetupViewController.view)
//            self.addChild(self.initialSetupViewController)
//            self.initialSetupViewController.didMove(toParent: self)
        })
    }
    
    @IBAction func editButtonAction(_ sender: Any) {
        editMode = !editMode
        self.updateEditButtonUI()
    }
    
    override func editAction(_ sender: UIButton?) {
        if let sender_ = sender {
            sender_.isSelected = !sender_.isSelected
        }
        editMode = !editMode
        self.updateEditButtonUI()
    }
    
}
