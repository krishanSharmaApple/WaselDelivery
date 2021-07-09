//
//  OrderCancelViewController.swift
//  WaselDelivery
//
//  Created by Purpletalk on 02/01/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift

class OrderCancelViewController: BaseViewController {

    @IBOutlet weak var orderTableView: UITableView!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var orderTableTopConstraint: NSLayoutConstraint!

    var showNotification: Any!
    var hideNotification: Any!
    var cancelReasonsList: [OrderCancelReason]?
    var order: Order?
    var commentText = ""
    var selectedCancelReason: OrderCancelReason?
    var reasonsRowCount = 1
    
    fileprivate var disposeObj: Disposable?
    var disposableBag = DisposeBag()

// MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Utilities.shouldHideTabCenterView(tabBarController, true)
        self.getCancelOrderReasons()
        addNavigationView()
        navigationView?.titleLabel.text = "Cancel Order"
        
        orderTableView.register(OrderCancelDetailsHeaderCell.nib(), forCellReuseIdentifier: OrderCancelDetailsHeaderCell.cellIdentifier())
        orderTableView.register(OrderCancelReasonsCell.nib(), forCellReuseIdentifier: OrderCancelReasonsCell.cellIdentifier())
        orderTableView.register(OrderCancelCommentsCell.nib(), forCellReuseIdentifier: OrderCancelCommentsCell.cellIdentifier())
        orderTableView.estimatedRowHeight = 110.0
        orderTableView.rowHeight = UITableView.automaticDimension
        orderTableView.tableHeaderView?.frame.size.height = 0.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyBoardNotification()
        Utilities.removeTransparentView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(showNotification)
        NotificationCenter.default.removeObserver(hideNotification)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.CANCEL_ORDER_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.CANCEL_ORDER_TAG)
    }

    override func navigateBack(_ sender: Any?) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

// MARK: - Notification Methods
    
    func registerForKeyBoardNotification() {
        showNotification = registerForKeyboardDidShowNotification(tableBottomConstraint, 0.0, shouldUseTabHeight: true, usingBlock: { _ in
            DispatchQueue.main.async(execute: {
//                self.orderTableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: .none, animated: false)
            })
        })
        hideNotification = registerForKeyboardWillHideNotification(tableBottomConstraint, 0.0)
    }
    
// MARK: - API Methods
    
    fileprivate func getCancelOrderReasons() {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        Utilities.showHUD(to: self.view, "")
        
        if let disposeObj_ = disposeObj {
            disposeObj_.dispose()
        }
        
        disposeObj =  ApiManager.shared.apiService.cancelOrderReasons().subscribe(onNext: { [weak self](cancelReasonsList_) in
            Utilities.hideHUD(from: self?.view)
            self?.cancelReasonsList = cancelReasonsList_
          
            var othersReason = OrderCancelReason()
            othersReason.id = 0
            othersReason.reason = "Other"
            self?.cancelReasonsList?.append(othersReason)
            
            self?.orderTableView.reloadData()
            }, onError: { [weak self](error) in
                Utilities.hideHUD(from: self?.view)
                if let error_ = error as? ResponseError {
                    if error_.getStatusCodeFromError() == .accessTokenExpire {
                        
                    } else {
                        Utilities.showToastWithMessage(error_.description())
                    }
                }
        })
        disposeObj?.disposed(by: disposableBag)
    }

}

extension OrderCancelViewController: UITableViewDelegate, UITableViewDataSource, OrderCancelCommentsCellProtocol {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (self.selectedCancelReason?.reason == "Other") ? 3 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (1 == section) ? reasonsRowCount : 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 1) ? 25.0 : 0.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let aView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.width, height: 25.0))
            let label = UILabel(frame: CGRect(x: 10.0, y: 0.0, width: tableView.bounds.width - 20.0, height: 25.0))
            label.text = "Please select the reason"
            label.font = UIFont.montserratLightWithSize(18.0)
            label.textColor = UIColor.selectedTextColor()
            aView.backgroundColor = UIColor.white
            aView.addSubview(label)
            return aView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (2 != indexPath.section) ? UITableView.automaticDimension : 100.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            guard let orderCancelDetailsHeaderCell = tableView.dequeueReusableCell(withIdentifier: OrderCancelDetailsHeaderCell.cellIdentifier(), for: indexPath) as? OrderCancelDetailsHeaderCell else {
                return UITableViewCell()
            }
            if let order_ = self.order {
                orderCancelDetailsHeaderCell.loadOrderDetails(order_: order_)
            }
            return orderCancelDetailsHeaderCell
        case 1:
            guard let orderCancelReasonsCell = tableView.dequeueReusableCell(withIdentifier: OrderCancelReasonsCell.cellIdentifier(), for: indexPath) as? OrderCancelReasonsCell else {
                return UITableViewCell()
            }
            if 0 == indexPath.row {
                orderCancelReasonsCell.loadCancelReasons(orderCancelReason_: selectedCancelReason, shouldShowArrowImageView: true, isReasonAvailable: (1 < reasonsRowCount))
            } else if let cancelReasonsList_ = self.cancelReasonsList {
                let reason_ = cancelReasonsList_[indexPath.row-1]
                orderCancelReasonsCell.loadCancelReasons(orderCancelReason_: reason_, shouldShowArrowImageView: false, isReasonAvailable: (1 < reasonsRowCount))
            }
            return orderCancelReasonsCell
        case 2:
            guard let orderCancelCommentsCell = tableView.dequeueReusableCell(withIdentifier: OrderCancelCommentsCell.cellIdentifier(), for: indexPath) as? OrderCancelCommentsCell else {
                return UITableViewCell()
            }
            orderCancelCommentsCell.delegate = self
            orderCancelCommentsCell.commentsTextView.inputAccessoryView = toolBar
            orderCancelCommentsCell.loadCommentsData(commentText: commentText)
            return orderCancelCommentsCell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if 1 == indexPath.section {
            if 0 == indexPath.row {
                self.selectedCancelReason = nil
                if let reasonsCount = self.cancelReasonsList?.count, 0 < reasonsCount {
                    reasonsRowCount = reasonsCount + 1
                }
            } else if let cancelReasonsList_ = self.cancelReasonsList {
                let reason_ = cancelReasonsList_[indexPath.row-1]
                self.selectedCancelReason = reason_
                if let reasonsCount = self.cancelReasonsList?.count, reasonsCount != indexPath.row {
                    commentText = ""
                }
                reasonsRowCount = 1
            }
            tableView.reloadData()
        }
    }

// MARK: - IBActions
    
    @IBAction func cancelOrderButtonAction(_ sender: Any) {
        if self.selectedCancelReason?.reason == "Other" {
            if true == commentText.isEmpty {
                Utilities.showToastWithMessage("Please enter a reason", position: ToastPositon.middle)
                return
            }
        } else if nil == self.selectedCancelReason?.reason {
            Utilities.showToastWithMessage("Please select the reason", position: ToastPositon.middle)
            return
        }
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Are you sure?", text: "Do you really want to cancel this order?", buttonText: "Cancel", cancelButtonText: "YES")
        responder.addCancelAction({
            DispatchQueue.main.async(execute: {
                self.cancelOrder()
            })
        })
    }
    
    @IBAction func done(_ sender: Any) {
        view.endEditing(true)
    }
    
// MARK: - User defined methods

    func textViewDidChangeCharacters(_ textView: UITextView) {
        commentText = textView.text
        let size = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: size.width,
                                                   height: CGFloat.greatestFiniteMagnitude))
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            orderTableView.beginUpdates()
            orderTableView.endUpdates()
            UIView.setAnimationsEnabled(true)
//            orderTableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: .bottom, animated: false)
        }
    }
    
// MARK: - User defined methods
    
    func cancelOrder() {
        if let orderId_ = self.order?.id {
            guard Utilities.shared.isNetworkReachable() else {
                showNoInternetMessage()
                return
            }
            
            Utilities.showHUD(to: self.view, "")
            
            if let disposeObj_ = disposeObj {
                disposeObj_.dispose()
            }
            
            let reasonId = self.selectedCancelReason?.id ?? 0
            let reasonComment_ = (true == commentText.isEmpty) ? (self.selectedCancelReason?.reason ?? "") : commentText
            let requestObj: [String: AnyObject] = ["orderId": String(orderId_) as AnyObject,
                                                   "reason": reasonId as AnyObject,
                                                   "comment": reasonComment_ as AnyObject]
            
            var params: [String: Any] = [
                "OrderID": String(orderId_),
                "CartID": self.order?.cartId == nil ? "" : "\(self.order?.cartId ?? 0)"
            ]
            let reasonMessage = self.selectedCancelReason?.reason ?? ""
            if false == reasonMessage.isEmpty {
                params["ReasonType"] = reasonMessage
            }
            if false == commentText.isEmpty {
                params["Reason"] = commentText
            }

            disposeObj =  ApiManager.shared.apiService.cancelOrder(requestObj).subscribe(onNext: { [weak self](_) in
                Utilities.hideHUD(from: self?.view)
                UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CANCEL_ORDER_EVENT, params: params)
                self?.navigationController?.popViewController(animated: true)
                }, onError: { [weak self](error) in
                    Utilities.hideHUD(from: self?.view)
                    if let error_ = error as? ResponseError {
                        if error_.getStatusCodeFromError() == .accessTokenExpire {
                            
                        } else {
                            Utilities.showToastWithMessage(error_.description())
                        }
                    }
            })
            disposeObj?.disposed(by: disposableBag)
        }
    }
    
}
