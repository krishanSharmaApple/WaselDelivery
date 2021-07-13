//
//  ConfirmOrderController.swift
//  WaselDelivery
//
//  Created by sunanda on 11/14/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import SDWebImage
import RxSwift
import iCarousel

class ConfirmOrderController: BaseViewController, AddressProtocol, CouponProtocol, SchedulePickUpTimeProtocol, PayTabsPaymentDelegate, BenefitPaymentDelegate {
    
    @IBOutlet weak var couponSuccessView: UIView!
    @IBOutlet weak var couponSuccessLabel: UILabel!
    @IBOutlet weak var tickView: UIView!

    @IBOutlet weak var openImage: UIImageView!
    @IBOutlet weak var granTotalView: UIView!
    @IBOutlet weak var billDetailsView: UIView!
    @IBOutlet weak var expandCollapseButton: UIButton!
    @IBOutlet weak var grandTotalLabel: UILabel!
    @IBOutlet weak var sectionView: UIView!
    @IBOutlet weak var driverTipView: DriverTipView!
    @IBOutlet weak var confirmOrderTableView: UITableView!
    @IBOutlet weak var paymentModeTableView: UITableView!
    @IBOutlet weak var costDetailTableView: UITableView!
    @IBOutlet weak var heightOfCostDetailTable: NSLayoutConstraint!
    @IBOutlet var paymentButtonCollection: [UIButton]!
    @IBOutlet var paymentTitleCollection: [UILabel]!
    @IBOutlet var subTitleCollection: [UILabel]!
    @IBOutlet weak var doneLabel: UILabel!
    @IBOutlet weak var checkOutButton: UIButton!
    
    @IBOutlet weak var tipForDriverView: UIView!
    @IBOutlet weak var tipForDriverPopUpHeaderLabel: UILabel!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var doneViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var paymentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var paymentViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var datePickerBgView: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    fileprivate var addresses: [Address]?
    private var paymentsMode = PaymentsMode()
    private let viewHeight: CGFloat = 500
    private var selectedAddressIndex: Int = -1
    fileprivate var selectedCoupon: Coupon?
    fileprivate var discountAmount: Double = 0.0
    
    fileprivate var disposeObj: Disposable?
    var disposableBag = DisposeBag()
    
    var orderType: OrderType?
    var specialOrder: SpecialOrder?
    var vehicleType: VehicleType?
    var costStructure = CostStruct()
    var isVendorOutLet: Bool = false

    var shouldRepeatOrder = false
    var outlet: Outlet? {
        didSet {
            costStructure.handlingFee = outlet?.handleFee ?? 0
            costStructure.handlingFeeType = outlet?.handleFeeType ?? "PERCENTAGE"
            costStructure.isPartner = outlet?.isPartnerOutLet ?? false
        }
    }
    var isPickedSchedulePickUpTime: Bool = false
    var isPreBookingAvailable: Bool = false
    var tipFils = 0
    var orderDetailsDelegate: OrderDetailsDelegate?

//    // MARK: Paytabs merchant email and secret key for live accounts
//
//    let benfitMerchantEmail = "hitinder.bawani@almoayyed.com.bh"
//    let benfitSecretKey = "VIzabFMzAbwjF3FZTHeAsIni7pe4z43vMCGYisySE5ck9Rk2yyC1h0jopxtZCxuoaansDVli0xC9pWcXvOYNPicfQFfscJRnUePy"
//
//    let creditCardMerchantEmail = "hitin@waseldelivery.com"
//    let creditCardSecretKey = "9LEdl7fZeXKOstNvzANdMObqEZ4tQk706MdrTtq8raXTELpdlcr71CxFBC9sXht34HvXaV6C63vKOVY98ph92PPDsZ6phztlhZjr"
//

    @IBOutlet weak var tipTextField: UITextField!
    var tips = [
        Tip(amount_: 300),
        Tip(amount_: 500),
        Tip(amount_: 700),
        Tip()
    ]
    var selectedTipIndex = -1
    var isFreeDelivery = Int()
// MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let footerView = UIView()
        footerView.backgroundColor = UIColor(red: 249 / 255, green: 249 / 255, blue: 249 / 255, alpha: 1)
        costDetailTableView.tableFooterView = footerView
        costDetailTableView.isScrollEnabled = false
        
        costStructure.orderCost = Utilities.shared.getTotalCost()
        costStructure.isFleetType = false
        if let outlet_ = outlet, true == outlet_.isFleetOutLet {
            costStructure.isFleetType = true
        } else if let outlet_ = Utilities.shared.currentOutlet, true == outlet_.isFleetOutLet {
            costStructure.isFleetType = true
        }
        
        setTip()
        tipTextField.inputAccessoryView = UIView()
        tipTextField.clearButtonMode = .always
        
        self.tipForDriverView.frame = self.view.frame
        self.tipForDriverView.center = self.view.center
        self.view.addSubview(tipForDriverView)
        self.tipForDriverView.isHidden = true

        addNavigationView()
        loadOrderCostDetails()
        confirmOrderTableView.estimatedRowHeight = 46.0
        confirmOrderTableView.rowHeight = UITableView.automaticDimension

//        openImage.isHidden = !Utilities.shared.isSmallDevice
        navigationView?.titleLabel.text = "Confirm Order"
        if let user = Utilities.getUser(), let address_ = user.addresses {
            self.addresses = address_
        }
        getAddresses()
        self.addSchedulePickUpPicker()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPaymentView(_:)))
        dimView.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(makeOrder), name: NSNotification.Name(rawValue: PayTabsPaymentNotification), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(updateAppOpenCloseStateUI), name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkOutButton.backgroundColor = UIColor(red: (85.0/255.0), green: (190.0/255.0), blue: (109.0/255.0), alpha: isAppOpen ? 1.0
            : 0.5)
        checkOutButton.isEnabled = isAppOpen
        
        paymentModeTableView.tableFooterView = UIView(frame: CGRect.zero)
        paymentModeTableView.register(PaymentModeTableViewCell.nib(), forCellReuseIdentifier: PaymentModeTableViewCell.cellIdentifier())
        paymentModeTableView.estimatedRowHeight = 70.0
        paymentModeTableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if true == Utilities.shared.isIphoneX() {
            topViewConstraint.constant = 20.0
        } else {
            topViewConstraint.constant = 0.0
        }
        self.configurePaymethods()
        self.updatePreBookingStatus()
        self.updateMinAndMaxDateForDelivery()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let disposeObj_ = disposeObj {
            disposeObj_.dispose()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.CONFIRM_ORDER_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.CONFIRM_ORDER_TAG)
    }
    
    deinit {
        self.resetTipValues()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: PayTabsPaymentNotification), object: nil)
    }
    
// MARK: - Notification Refresh methods
    
    @objc private func updateAppOpenCloseStateUI() {
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkOutButton.backgroundColor = UIColor(red: (85.0/255.0), green: (190.0/255.0), blue: (109.0/255.0), alpha: isAppOpen ? 1.0
            : 0.5)
        checkOutButton.isEnabled = isAppOpen
        UIView.performWithoutAnimation {
            self.confirmOrderTableView.reloadData()
            self.reloadDriverTipView()
            self.reloadCostDetailTable()
        }
    }

    override func navigateBack(_ sender: Any?) {
        if nil != specialOrder {
            navigationController?.dismiss(animated: true, completion: nil)
        } else {
            super.navigateBack(nil)
        }
        orderDetailsDelegate?.changedOrderInfo()
    }
    
// MARK: - IBActions
    
    fileprivate func addNewAddress(_ sender: Any?) {
        let storyboard = Utilities.getStoryBoard(forName: .checkOut)
        if let addAddressController = storyboard.instantiateViewController(withIdentifier: "AddAddressController") as? AddAddressController {
            navigationController?.pushViewController(addAddressController, animated: true)
        }
    }
    
    @IBAction func pickUpClearButtonAction(_ sender: Any) {
        Utilities.shared.cart.deliveryDate = nil
        self.datePickerBgView.isHidden = true
        UIView.performWithoutAnimation {
            self.confirmOrderTableView.reloadSections(NSMutableIndexSet(index: 0) as IndexSet, with: .none)
        }
    }
    
    @IBAction func pickUpdoneButtonAction(_ sender: Any) {
        
        func outletOpenForSchudledDate(outlet_: Outlet) -> Bool {
            let weekday = Utilities.getWeekDay(date: self.datePicker.date)
            debugPrint(weekday)

            if let outletTimings_ = outlet_.outletTimings {

                // below code is added for temperary solution.(11/01/19 03:30pm by ramchandra)
                if weekday >= outletTimings_.count {
                    Utilities.showToastWithMessage(NSLocalizedString("Services are not available on selected date.", comment: ""), position: .middle, duration: 2.0)
                    self.datePickerBgView.isHidden = true
                    return false
                }

                let outletTimings_ = outletTimings_[weekday]
                if false == outletTimings_.available {
                    Utilities.showToastWithMessage(NSLocalizedString("Services are not available on selected date.", comment: ""), position: .middle, duration: 2.0)
                    return false
                }
                let isOutletOpenForSchudledDate = Utilities.isOutletOpenForSchudledDate(outletTimings_, schudledDate: self.datePicker.date)
                if false == isOutletOpenForSchudledDate.isOpen {
                    Utilities.showToastWithMessage(isOutletOpenForSchudledDate.message, position: .middle, duration: 2.0)
                }
                return isOutletOpenForSchudledDate.isOpen
            }
            return false
        }
        
        func appOpenForSchudledDate() -> Bool {
            if let appTimings = Utilities.shared.appTimings {
                let weekday = Utilities.getWeekDay(date: self.datePicker.date)
                debugPrint(weekday)
                
                let outletTimings_ = appTimings[weekday]
                if false == outletTimings_.available {
                    Utilities.showToastWithMessage(NSLocalizedString("Services are not available on selected date.", comment: ""), position: .middle, duration: 2.0)
                    return false
                }
                let isOutletOpenForSchudledDate = Utilities.isOutletOpenForSchudledDate(outletTimings_, schudledDate: self.datePicker.date)
                if false == isOutletOpenForSchudledDate.isOpen {
                    Utilities.showToastWithMessage(isOutletOpenForSchudledDate.message, position: .middle, duration: 2.0)
                }
                return isOutletOpenForSchudledDate.isOpen
            }
            return false
        }
        
        if let outlet_ = Utilities.shared.currentOutlet, let orderType_ = orderType, orderType_ == .normal {
            if false == outletOpenForSchudledDate(outlet_: outlet_) {
                return
            }
        } else if true == isVendorOutLet {
            if let outlet_ = Utilities.shared.currentOutlet, let orderType_ = orderType, orderType_ == .special {
                if false == outletOpenForSchudledDate(outlet_: outlet_) {
                    return
                }
            }
        } else if let outlet_ = self.outlet {
            if false == outletOpenForSchudledDate(outlet_: outlet_) {
                return
            }
        } else {// Special order
            if false == appOpenForSchudledDate() {
                return
            }
        }

        Utilities.shared.cart.deliveryDate = self.datePicker.date
        self.datePickerBgView.isHidden = true
        UIView.performWithoutAnimation {
            self.confirmOrderTableView.reloadSections(NSMutableIndexSet(index: 0) as IndexSet, with: .none)
        }
    }

    @IBAction func datePickerChanged(_ sender: Any) {
        debugPrint(self.datePicker.date)
    }
    
    @IBAction func confirmOrder(_ sender: Any) {
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkOutButton.isEnabled = isAppOpen
        if false == isAppOpen {
            return
        }

        guard let `addresses` = addresses, addresses.count > 0 else {
            Utilities.showToastWithMessage("Please add address to proceed.")
            return
        }
        
        guard selectedAddressIndex != -1 else {
            Utilities.showToastWithMessage("Please select address to proceed.")
            return
        }

        if 0 > costStructure.deliveryCharge {
            Utilities.showToastWithMessage(NotServingLocationMessage)
            return
        }

        paymentModeTableView.isScrollEnabled = false
        paymentViewBottomConstraint.constant = 0.0
        paymentViewHeightConstraint.constant = 180.0 + paymentModeTableView.contentSize.height
//        (70.0*CGFloat(paymentsMode.paymentModeEnumDictionary.count))

        paymentModeTableView.isHidden = (0 >= paymentsMode.paymentModeEnumDictionary.count)

        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn], animations: {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.dimView.isUserInteractionEnabled = true
            self.dimView.backgroundColor = UIColor(red: (53.0/255.0), green: (53.0/255.0), blue: (53.0/255.0), alpha: 0.7)
        }, completion: nil)
    }
    
    @IBAction func done(_ sender: Any?) {
        
        if false == Utilities.isWaselDeliveryOpen() {
            return
        }
        guard isOutletOpen() == true else {
            return
        }
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        self.makeOrder()
    }
    
    @IBAction func selectPaymentMode(_ sender: UIButton) {
        paymentButtonCollection[0].isSelected = (sender.tag == 10)
        paymentButtonCollection[1].isSelected = !(sender.tag == 10)
        if #available(iOS 10.0, *) {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }

        for label in paymentTitleCollection {
            label.textColor = (label.tag == sender.tag + 1) ? UIColor.themeColor() : UIColor.unSelectedColor()
        }
        for label in subTitleCollection {
            label.textColor = (label.tag == sender.tag + 2) ? .selectedTextColor() : UIColor.selectedColor()
            label.alpha = (label.tag == sender.tag + 2) ? 1.0 : 0.5
        }
        paymentsMode.selectedMode = (sender.tag == 10) ? PaymentMode.cashOrCard : PaymentMode.creditCard
    }
    
    @IBAction func applyCoupon(_ sender: Any?) {
        guard let orderType_ = orderType, orderType_ == .normal else {
            Utilities.showToastWithMessage("Coupon can't be applied for special order.")
            return
        }
        
        let addAddressController = ApplyCouponController.instantiateFromStoryBoard(.checkOut)
        addAddressController.delegate = self
        navigationController?.pushViewController(addAddressController, animated: true)
    }
    
    @IBAction func expandCollapseAction(_ sender: Any) {
        loadOrderCostDetails()
        expandCollapseButton.isSelected = !expandCollapseButton.isSelected
        granTotalView.isHidden = expandCollapseButton.isSelected
        billDetailsView.isHidden = !expandCollapseButton.isSelected
        reloadCostDetailTable()
    }
    
    @IBAction func dismissTipField(_ sender: UIButton) {
        self.tipForDriverView.isHidden = true
        tipTextField.resignFirstResponder()
        let text_ = tipTextField.text ?? ""
        let tip = Double(text_) ?? -1
        Utilities.shared.cart.tip = tip.getFills()
        self.tipFils = Utilities.shared.cart.tip
        setTip()
        loadOrderCostDetails()
        UIView.performWithoutAnimation {
            reloadDriverTipView()
            reloadCostDetailTable()
        }
    }
    
    @IBAction func cancelTipButtonAction(_ sender: UIButton) {
        if self.tipFils != Utilities.shared.cart.tip {
            let dinams = Utilities.shared.cart.tip.getDinams()
            tipTextField.text = dinams > 0 ? "\(String(format: "%.3f", dinams))" : ""
            setTip()
            loadOrderCostDetails()
            UIView.performWithoutAnimation {
                reloadDriverTipView()
                reloadCostDetailTable()
            }
        }
        self.tipForDriverView.isHidden = true
        tipTextField.resignFirstResponder()
    }
    
    @IBAction func incrementTipButtonAction(_ sender: UIButton) {
        tipFils += 0.1.getFills()
        let dinams = tipFils.getDinams()
        tipTextField.text = dinams > 0 ? "\(String(format: "%.3f", dinams))" : ""
        setTip()
    }
    
    @IBAction func decrementTipButtonAction(_ sender: UIButton) {
        tipFils -= 0.1.getFills()
        tipFils = max(0, tipFils)
        let dinams = tipFils.getDinams()
        tipTextField.text = dinams > 0 ? "\(String(format: "%.3f", dinams))" : ""
        setTip()
    }

    func setTip() {
        let fils = Utilities.shared.cart.tip
        if fils > 0 {
            switch fils {
            case 300:
                selectedTipIndex = 0
                tips[tips.count - 1].amount = -1
            case 500:
                selectedTipIndex = 1
                tips[tips.count - 1].amount = -1
            case 700:
                selectedTipIndex = 2
                tips[tips.count - 1].amount = -1
            default:
                selectedTipIndex = 3
            }
            tips[selectedTipIndex].amount = fils
            costStructure.tip = fils.getDinams()
        } else {
            self.resetTipValues()
        }
    }
    
    func resetTipValues() {
        selectedTipIndex = -1
        Utilities.shared.cart.tip = 0
        costStructure.tip = 0.0
        tips[tips.count - 1].amount = -1
    }

    func reloadCostDetailTable() {
        costDetailTableView.reloadData()
        view.layoutIfNeeded()
        DispatchQueue.main.async {
            self.heightOfCostDetailTable.constant = self.costDetailTableView.contentSize.height
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }

    func reloadDriverTipView() {
        var tip = Tip()
        if selectedTipIndex != -1 && selectedTipIndex < tips.count {
            tip = tips[selectedTipIndex]
        }
        driverTipView.updateTipAmount(tip: tip)
    }

// MARK: API Methods
    
    private func placeOrder(_ orderObject: [String: Any]) {
        Utilities.showHUD(to: self.view, "Confirming...")

        disposeObj = ApiManager.shared.apiService.placeOrder(orderObject as [String: AnyObject]).subscribe(
            onNext: { [weak self] (order) in
                Utilities.hideHUD(from: self?.view)
                if let order_ = order as? Order {
                    if self?.paymentsMode.selectedMode == .cashOrCard {
                        self?.showOrderSuccesView(order_)
                    } else if self?.paymentsMode.selectedMode == .creditCard { // Should not get here
        //                self?.navigateToPayTabsSdk(order_: order_)
                    } else if self?.paymentsMode.selectedMode == .benfit {
//                        self?.navigateToPayTabsSdk(order_: order_)

                        self?.startBenefitFlow(order:order_)

                        return
                    }
                } else if let removedItems_ = order as? [OutletItem] {
                    if Utilities.shared.cart.cartItems.count == removedItems_.count {
                        self?.clearSavedCart()
                        self?.showOrderCancelAlert()
                    } else {
                        self?.showUnprocessedOrderAlert(removedItems: removedItems_)
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
    
    var transaction: Transaction = Transaction()
    var masterCardOrder: Order?
    var masterCardDebugMode = true

    /*func startMasterCardFlow(order: Order) {
        let ccInputVC = UIStoryboard.init(name: "CheckOut", bundle: nil).instantiateViewController(withIdentifier: "CreditCardInputViewController") as! CreditCardInputViewController
        ccInputVC.didInputCCInfoHandler = { cardData in
            self.masterCardOrder = order
            self.startMasterCardPayment(cardData: cardData)
        }
        self.present(ccInputVC, animated: true, completion: nil)
    }

    func masterCardFlowEnded() {
        if masterCardOrder != nil {
            self.completeOrder(order: masterCardOrder!)
        } else {
            Utilities.hideHUD(from: self.view)

            Utilities.showMasterCardAlertMessage("Invalid order - Error 3")
            print("somehow mastercard order is nil")
        }
    }*/

    /*func startMasterCardPayment(cardData: [String: String]) {
        Utilities.showHUD(to: self.view, "Payment in progress")

        self.merchantAPI.createSession { (result) in
            DispatchQueue.main.async {
                // stop the activity indictor
                guard case .success(let response) = result,
                    "SUCCESS" == response[at: "gatewayResponse.result"] as? String,
                    let session = response[at: "gatewayResponse.session.id"] as? String,
                    let apiVersion = response[at: "apiVersion"] as? String else {
                        // if anything was missing, flag the step as having errored
                        print("Error Creating Session")

                        Utilities.hideHUD(from: self.view)
                        Utilities.showMasterCardAlertMessage("Error Creating Session")

                        return
                }


                self.transaction.session = GatewaySession(id: session, apiVersion: apiVersion)
                self.transaction.nameOnCard = cardData["name"]
                self.transaction.cardNumber = cardData["number"]
                self.transaction.expiryYY = cardData["year"]
                self.transaction.expiryMM = cardData["month"]
                self.transaction.cvv = cardData["cvv"]

                self.getCardToken(transaction: self.transaction)

                guard let order = self.masterCardOrder else {
                    print("no order?")
                    Utilities.hideHUD(from: self.view)
                    Utilities.showMasterCardAlertMessage("Invalid order - Error 2")

                    return
                }

                self.transaction.amount = NSDecimalNumber(value: self.masterCardDebugMode ? 0.01 : (order.grandTotal ?? 0))

                guard let sessionId = self.transaction.session?.id, let mcApiVersion = self.transaction.session?.apiVersion else { return }

                var request = GatewayMap()
                request[at: "sourceOfFunds.provided.card.nameOnCard"] = self.transaction.nameOnCard
                request[at: "sourceOfFunds.provided.card.number"] = self.transaction.cardNumber
                request[at: "sourceOfFunds.provided.card.securityCode"] = self.transaction.cvv
                request[at: "sourceOfFunds.provided.card.expiry.month"] = self.transaction.expiryMM
                request[at: "sourceOfFunds.provided.card.expiry.year"] = self.transaction.expiryYY

                // if the transaction has an Apple Pay Token, populate that into the map
                if let tokenData = self.transaction.applePayPayment?.token.paymentData, let token = String(data: tokenData, encoding: .utf8) {
                    request[at: "sourceOfFunds.provided.card.devicePayment.paymentToken"] = token
                }

                // execute the update
                self.gateway.updateSession(sessionId, apiVersion: mcApiVersion, payload: request, completion: self.updateSessionHandler(_:))
            }
        }
    }*/

    /*func getCardToken(transaction: Transaction) {
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Basic bWVyY2hhbnQuRTE0MzA1OTUwOjc0ZGYyZGZmZjJiYjk1YmEzMjEyMGMyNTQ2YWZiOWMw"
        ]
        let parameters = ["sourceOfFunds": [
            "provided": ["card": [
                "expiry": [
                    "month": transaction.expiryMM,
                    "year": transaction.expiryYY
                ],
                "number": transaction.cardNumber,
                "securityCode": transaction.cvv
                ]],
            "type": "CARD"
            ]] as [String : Any]

        let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])

        let request = NSMutableURLRequest(url: NSURL(string: "https://credimax.gateway.mastercard.com/api/rest/version/49/merchant/E14305950/token")! as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil && data != nil) {
                print(error)
                print("Mastercard tokenization failed: \(error?.localizedDescription)")
            } else {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options:[]) as? [String: Any] else {
                        print("Mastercard tokenization failed: json is not dict")
                        return
                    }

                    if let cardToken = json["token"] as? String {
                        print("Mastercard tokenization success: \(cardToken)")

                        UserDefaults.standard.set(cardToken, forKey: "\(self.masterCardOrder?.id ?? 0)")
                    } else {
                        print("Mastercard tokenization failed: \(json)")
                    }

                } catch let parseError as NSError {
                    print("Error with Json: \(parseError)")
                    print("Mastercard tokenization failed: \(parseError)")
                }
            }
        })

        dataTask.resume()
    }

    fileprivate func updateSessionHandler(_ result: GatewayResult<GatewayMap>) {
        DispatchQueue.main.async {
            guard case .success(_) = result else {
//                self.stepErrored(message: "Error Updating Session", stepStatusImageView: self.updateSessionStatusImageView)
                print("Error Updating Session")
                Utilities.hideHUD(from: self.view)
                Utilities.showMasterCardAlertMessage("Error Updating Session")

                return
            }

            // check for 3DS enrollment
            self.check3dsEnrollment()
        }
    }

    func check3dsEnrollment() {
        let redirectURL = self.merchantAPI.merchantServerURL.absoluteString.appending("/3DSecureResult.php?3DSecureId=\(transaction.threeDSecureId!)")

        self.merchantAPI.check3DSEnrollment(transaction: transaction, redirectURL: redirectURL , completion: check3DSEnrollmentHandler)
    }

    func check3DSEnrollmentHandler(_ result: Result<GatewayMap>) {
        DispatchQueue.main.async {
            self.check3DSEnrollmentv47Handler(result)
        }
    }

    func check3DSEnrollmentv47Handler(_ result: Result<GatewayMap>) {
        guard case .success(let response) = result, let recommendaition = response[at: "gatewayResponse.response.gatewayRecommendation"] as? String else {
            print("Error checking 3DS Enrollment")
            Utilities.hideHUD(from: self.view)
            Utilities.showMasterCardAlertMessage("Error checking 3DS Enrollment")

            return
        }

        if recommendaition == "DO_NOT_PROCEED" {
            print("3DS Do Not Proceed")
        }

        // if PROCEED in recommendation, and we have HTML for 3DS, perform 3DS
        if let html = response[at: "gatewayResponse.3DSecure.authenticationRedirect.simple.htmlBodyContent"] as? String {
            self.begin3DSAuth(simple: html)
        } else {
            // if PROCEED in recommendation, but no HTML, finish the transaction without 3DS
            self.processPayment()
        }
    }

    fileprivate func begin3DSAuth(simple: String) {
        // instatniate the Gateway 3DSecureViewController and present it
        Utilities.hideHUD(from: self.view)

        let threeDSecureView = Gateway3DSecureViewController(nibName: nil, bundle: nil)

        present(threeDSecureView, animated: true)

        // Optionally customize the presentation
        threeDSecureView.title = "3-D Secure Auth"
//        threeDSecureView.navBar.tintColor = brandColor

        // Start 3D Secure authentication by providing the view with the HTML content provided by the check enrollment step
        threeDSecureView.authenticatePayer(htmlBodyContent: simple, handler: handle3DS(authView:result:))
    }

    func handle3DS(authView: Gateway3DSecureViewController, result: Gateway3DSecureResult) {
        // dismiss the 3DSecureViewController
        authView.dismiss(animated: true, completion: {
            switch result {
            case .error(_):
//                self.stepErrored(message: "3DS Authentication Failed", stepStatusImageView: self.check3dsStatusImageView)
                print("3DS Authentication Failed")
                Utilities.showMasterCardAlertMessage("3DS Authentication Failed")

            case .completed(gatewayResult: let response):
                // check for version 46 and earlier api authentication failures and then version 47+ failures
                if Int(self.transaction.session!.apiVersion)! <= 46, let status = response[at: "3DSecure.summaryStatus"] as? String , status == "AUTHENTICATION_FAILED" {
                    print("3DS Authentication Failed")
                    Utilities.showMasterCardAlertMessage("3DS Authentication Failed")
//                    self.stepErrored(message: "3DS Authentication Failed", stepStatusImageView: self.check3dsStatusImageView)
                } else if let status = response[at: "response.gatewayRecommendation"] as? String, status == "DO_NOT_PROCEED"  {
//                    self.stepErrored(message: "3DS Authentication Failed", stepStatusImageView: self.check3dsStatusImageView)
                    print("3DS Authentication Failed")
                    Utilities.showMasterCardAlertMessage("3DS Authentication Failed")
                } else {

                    self.processPayment()

                    Utilities.showHUD(to: self.view, "Processing payment")

                }
            default:
                print("3DS Authentication Cancelled")
                Utilities.showMasterCardAlertMessage("3DS Authentication Cancelled")
            }
        })
    }*/

    func startBenefitFlow(order: Order) {
        Utilities.showHUD(to: self.view, "Preparing Benefit gateway")

        var itemsString = ""
        if let orderItems = order.items {
            for item in orderItems {
                itemsString.append("\(item.name ?? "name") - \(item.price ?? 0.0)\n")
            }
        }

        let params: [String: Any] = ["price": order.grandTotal ?? 0.0, "orderId": "\(order.id ?? 3)",
            "udf2": self.removeSpecialCharsFromString(text: order.shippingAddress?.formattedAddress ?? "shipping address"), "udf3": self.removeSpecialCharsFromString(text: itemsString), "udf4": self.removeSpecialCharsFromString(text: order.pickUpLocation ?? "pickup location"), "udf5": self.removeSpecialCharsFromString(text: order.outlet?.name ?? "store name")]

        print(params)

        var request = URLRequest(url: URL(string: "\(baseUrl)/api/v1/paytabs/benefit")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            debugPrint(response ?? "Empty response")
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                print(json)

                DispatchQueue.main.async {
                    Utilities.hideHUD(from: self.view)
                }

                if let paymentID = json["success"] as? String {
                    DispatchQueue.main.async {
                        let finalURL = "\(baseUrl)/benefit?pid=" + paymentID

                        self.openBenefitWebView(order: order, url: finalURL)
                    }
                } else {
                    var error = "Invalid response - No PaymentID"
                    if let jsonError = json["error"] as? String {
                        error = jsonError
                    }

                    Utilities.showBenefitAlertMessage(error)
                }

            } catch {
                print("error")
                Utilities.showBenefitAlertMessage("Invalid response from Benefit portal")
            }
        })

        task.resume()
    }

    func openBenefitWebView(order: Order, url: String) {
        let benefitVC = UIStoryboard.init(name: "CheckOut", bundle: nil).instantiateViewController(withIdentifier: "BenefitWebViewController") as! BenefitWebViewController

        benefitVC.paymentURL = url

        benefitVC.didCancelPaymentHandler = {
            self.paymentsMode.selectedMode = .benfit
            self.paymentModeTableView.reloadData()

            benefitVC.dismiss(animated: true, completion: nil)
        }

        benefitVC.didFinishPaymentHandler = {
            benefitVC.dismiss(animated: true, completion: {
                self.markOrderAsPayed(order: order)
            })
        }

        benefitVC.didFailPaymentHandler = {
            self.paymentsMode.selectedMode = .benfit
            self.paymentModeTableView.reloadData()

            benefitVC.dismiss(animated: true, completion: {
                Utilities.showBenefitAlertMessage("Payment failed, please try again later")
            })
            Utilities.hideHUD(from: self.view)
        }

        self.present(benefitVC, animated: true, completion: nil)
    }

    /*func processPayment() {
        // update the UI
        self.merchantAPI.completeSession(transaction: transaction) { (result) in
            DispatchQueue.main.async {
                self.processPaymentHandler(result: result)
            }
        }
    }

    func processPaymentHandler(result: Result<GatewayMap>) {
        guard case .success(let response) = result, "SUCCESS" == response[at: "gatewayResponse.result"] as? String else {
            print("Unable to complete Pay Operation")
            Utilities.hideHUD(from: self.view)
            Utilities.showMasterCardAlertMessage("Transaction was declined")

            return
        }

        self.masterCardFlowEnded()
    }*/

    func navigateToPayTabsSdk(_ orderInfo: [String: Any]/*, order_: Order*/) {
        if paymentsMode.selectedMode != .cashOrCard {
//            if paymentsMode.selectedMode == .benfit {
//                self.callBenifitPayPage(order_: order_, grandTotal: Float(costStructure.grandTotal), completionHandler: { (isTransactionCompleted, paymentUrl) in
//                    if true == isTransactionCompleted {
//                        if false == paymentUrl.isEmpty {
//                            debugPrint(paymentUrl)
//                            DispatchQueue.main.async {
//                                let waselController = WaselController.instantiateFromStoryBoard(.profile)
//                                waselController.isPaymentFlow = true
//                                waselController.paymentUrl = paymentUrl
//                                waselController.order_ = order_
//                                waselController.benefitPaymentDelegate = self
//                                self.navigationController?.pushViewController(waselController, animated: true)
//                            }
//                        }
//                    }
//                })
//                return
//            }
            
            let cardPaymentViewController = CardPaymentViewController.init(nibName: "CardPaymentViewController", bundle: nil)
            cardPaymentViewController.costStructure = costStructure
//            cardPaymentViewController.order_ = order_
            cardPaymentViewController.orderInfo = orderInfo
            cardPaymentViewController.payTabsPaymentDelegate = self
            self.navigationController?.pushViewController(cardPaymentViewController, animated: true)
            return
        }
    }
    
    func markOrderAsPayed(order: Order) {
        /*
         transaction.setCustomerEmail(loginCredentials.getEmail());
         transaction.setCustomerPassword("");
         transaction.setIsDefault(true);
         transaction.setOrderId(Integer.parseInt(order.getId()));
         transaction.setResponseCode("100");
         transaction.setToken("");
         transaction.setTransactionId(order.getId());
         */

        /*let requestParams0: [String: Any] = [
            "customerEmail": Utilities.getUser()?.email ?? "",
            "customerPassword": "",
             "isDefault": true,
            "orderId": order.id!,
            "responseCode": "100",
            "token": "",
            "transactionId": "\(order.id!)"
            ] as [String: Any]*/

        let requestParams: [String: Any] = ["customerEmail": Utilities.getUser()?.email ?? "", "customerPassword": Utilities.getUser()?.token ?? "", "isDefault": true, "orderId": order.id ?? 0, "responseCode": 100, "token": "", "transactionId": order.id ?? 0] as [String: Any]

        Utilities.showHUD(to: self.view, "")

        ApiManager.shared.apiService.paymentUpdate(requestParams as [String: AnyObject]).subscribe(
            onNext: { [weak self] (updatedOrder) in
                Utilities.hideHUD(from: self?.view)

                self?.showOrderSuccesView(order)

            }, onError: { [weak self] (error) in
                Utilities.hideHUD(from: self?.view)

                if let error_ = error as? ResponseError {
                    Utilities.showToastWithMessage(error_.description())
                }
        }).disposed(by: disposableBag)
    }

    func completeOrder(order: Order) {
        var cardToken = ""
        if let userDefaultsToken = UserDefaults.standard.string(forKey: "\(self.masterCardOrder?.id ?? 0)") {
            cardToken = userDefaultsToken
        }

        let requestParams: [String: Any] = ["customerEmail": Utilities.getUser()?.email ?? "", "customerPassword": Utilities.getUser()?.token ?? "", "isDefault": true, "orderId": order.id ?? 0, "responseCode": 100, "token": cardToken, "transactionId": order.id ?? 0] as [String: Any]

        print(requestParams)

        ApiManager.shared.apiService.paymentUpdate(requestParams as [String: AnyObject]).subscribe(
            onNext: { [weak self] (updatedOrder) in
                Utilities.hideHUD(from: self?.view)

                self?.showOrderSuccesView(order)

            }, onError: { [weak self] (error) in
                Utilities.hideHUD(from: self?.view)

                if let error_ = error as? ResponseError {
                    Utilities.showToastWithMessage(error_.description())
                }
        }).disposed(by: disposableBag)
    }

    func updateTransactionStatus(order_: Order) {
        self.showOrderSuccesView(order_)
    }
    
    func updateBenefitPayTransactionStatus(order_: Order) {
        self.showOrderSuccesView(order_)
    }
        
    private func getCustomizationCost(orderItem_: OrderItem) -> Double {
        var customItemCost = 0.0
        if let customItems_ = orderItem_.customItems {
            _ = customItems_.map ({ (customItem) -> Double in
                customItemCost += customItem.price ?? 0.0
                return customItemCost
            })
        }
        return customItemCost
    }
    
    func callBenifitPayPage(order_: Order? = nil, grandTotal: Float? = 0.300, completionHandler: ((_ isCardSaved: Bool, _ paymentUrl: String) -> Void)? = nil) {
        
//        let waselDeliveryKeys = WaselDeliveryKeys()
        let merchantEmail_ = ""//waselDeliveryKeys.benefitMerchantEmail
        let secretKey_ = ""//waselDeliveryKeys.benefitSecretKey
        
        var productNames_ = ""
        var quantites_ = ""
        var prices_ = ""
        if let type_ = order_?.orderType, type_ == .special {
            productNames_ = "Delivery charge"
            quantites_ = String("1")
            prices_ = String(describing: grandTotal)
        } else if let items = order_?.items {
            _ = items.map ({ (item) -> String? in
                if let name_ = item.name, false == name_.isEmpty {
                    if false == productNames_.isEmpty {
                        productNames_.append(" || ")
                    }
                    productNames_.append(name_)
                    
                    if let quantity_ = item.quantity, 0 < quantity_ {
                        if false == quantites_.isEmpty {
                            quantites_.append(" || ")
                        }
                        quantites_.append(String(quantity_))
                    }
                    
                    if let price_ = item.price, 0 < price_ {
                        if false == prices_.isEmpty {
                            prices_.append(" || ")
                        }
                        let customizedItemCost = self.getCustomizationCost(orderItem_: item)
                        let itemCost_ = customizedItemCost + price_
                        prices_.append(String(itemCost_))
                    }
                    
                    return name_
                }
                return nil
            })
            
            if 0 < costStructure.deliveryCharge {
                if false == productNames_.isEmpty {
                    productNames_.append(" || ")
                }
                productNames_.append("Delivery charge")
                if false == quantites_.isEmpty {
                    quantites_.append(" || ")
                }
                quantites_.append(String("1"))
                if false == prices_.isEmpty {
                    prices_.append(" || ")
                }
                prices_.append(String(describing: costStructure.deliveryCharge))
            }
        }
        
        let orderId_ = String(order_?.id ?? 0)
        let userName_ = Utilities.getUser()?.name ?? ""
        let mobile_ = Utilities.getUser()?.mobile ?? ""
        let email_ = Utilities.getUser()?.email ?? ""
        let shippingAddress_ = order_?.shippingAddress?.doorNumber ?? "ManamaBahrain"
        let cityShipping_ = order_?.shippingAddress?.landmark ?? "Manama"
        var stateShipping_ = order_?.shippingAddress?.location ?? "Manama"
        if stateShipping_ == "0" {
           stateShipping_ = "Manama"
        }
        let discount_ = costStructure.discount
        let tipAmount_ = order_?.tipAmount ?? 0
        let total_ = (grandTotal ?? 0.300) + Float(discount_) //0.300 for BHD
        let dict = ["merchant_email": merchantEmail_,
                    "secret_key": secretKey_,
                    "currency": "BHD",
                    "amount": total_,
                    "discount": discount_,
                    "title": "WaselDelivery",
                    "phone_number": mobile_,
                    "order_id": orderId_,
                    "customer_email": email_,
                    "country": "BHR",
                    "billing_address": "Manama Bahrain",
                    "city": "Manama",
                    "state": "Manama",
                    "postal_code": "00973",
                    "site_url": "https://www.waseldelivery.com/", //baseUrl, //"https://80bef544.ngrok.io",
                    "cc_first_name": userName_,
                    "cc_last_name": userName_,
                    "cc_phone_number": mobile_,
                    "products_per_title": (true == productNames_.isEmpty) ? "Adding Card" : productNames_,
                    "reference_no": orderId_,
                    "ip_customer": "192.168.0.1",
                    "ip_merchant": "192.168.2.222",
                    "address_shipping": shippingAddress_,
                    "city_shipping": cityShipping_,
                    "state_shipping": stateShipping_,
                    "postal_code_shipping": "00973",
                    "country_shipping": "BHR",
                    "quantity": (true == quantites_.isEmpty) ? 1 : quantites_,
                    "unit_price": (true == prices_.isEmpty) ? 1 : prices_,
                    "return_url": baseUrl + "/api/v1/paytabs/benefit",
                    "email": email_,
                    "other_charges": tipAmount_,
                    "msg_lang": "en",
                    "cms_with_version": 4] as [String: Any]
        
        Utilities.showHUD(to: self.view, "")
        let url_ = URL(string: "https://www.paytabs.com/apiv2/create_pay_page") ?? URL(fileURLWithPath: "")
        let request = NSMutableURLRequest(url: url_)
        request.httpMethod = "POST"
        //                request.httpBody = jsonData
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        guard var components =  URLComponents(url: url_, resolvingAgainstBaseURL: false) else {
            fatalError("Unable to create URL components from \(url_)")
        }
        components.queryItems = dict.map {
            URLQueryItem(name: String($0), value: String(describing: $1))
        }
        if let query_ = components.query {
            request.httpBody = query_.data(using: .utf8)
        }
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, _, error in
            if error != nil {
                DispatchQueue.main.async {
                    Utilities.hideHUD(from: self.view)
                }
                if let errorMessage_ = error?.localizedDescription, false == errorMessage_.isEmpty {
                    Utilities.showToastWithMessage(errorMessage_, position: .middle)
                }
                
                debugPrint(error?.localizedDescription ?? "")
                if let acompletionHandler = completionHandler {
                    acompletionHandler(false, "")
                }
                return
            }
            
            do {
                DispatchQueue.main.async {
                    Utilities.hideHUD(from: self.view)
                }
                
                guard var jsonString = String(data: data ?? Data(), encoding: .utf8) else {
                    if let acompletionHandler = completionHandler {
                        acompletionHandler(false, "")
                    }
                    return
                }
                jsonString = jsonString.replacingOccurrences(of: "null", with: "")
                
                let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8) ?? Data(), options: .mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    if let resultValue: String = parseJSON["payment_url"] as? String, false == resultValue.isEmpty {
                        print("payment_url: \(resultValue)")
                        if let acompletionHandler = completionHandler {
                            acompletionHandler(true, resultValue)
                        }
                    } else {
                        let message_: String = parseJSON["result"] as? String ?? "Something went wrong."
                        Utilities.showToastWithMessage(message_, position: .middle)
                        if let acompletionHandler = completionHandler {
                            acompletionHandler(false, "")
                        }
                    }
                } else {
                    let message_: String = NSLocalizedString("Something went wrong.", comment: "")
                    Utilities.showToastWithMessage(message_, position: .middle)
                    if let acompletionHandler = completionHandler {
                        acompletionHandler(false, "")
                    }
                }
            } catch let error as NSError {
                debugPrint(error)
                DispatchQueue.main.async {
                    Utilities.hideHUD(from: self.view)
                }
                let errorMessage_ = error.localizedDescription
                if false == errorMessage_.isEmpty {
                    Utilities.showToastWithMessage(errorMessage_, position: .middle)
                }
                if let acompletionHandler = completionHandler {
                    acompletionHandler(false, "")
                }
            }
        }
        task.resume()
    }
    
    fileprivate func getAddresses() {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        let pickUpLocationObject = formPickUplocationObject()
        
        Utilities.showHUD(to: self.view, "")
        disposeObj = ApiManager.shared.apiService.getDeliveryCharge(pickUpLocationObject).subscribe(onNext: { [weak self](addresses_) in
            Utilities.hideHUD(from: self?.view)
            self?.addresses = addresses_
            self?.castAddress()
            self?.getDeliveryChargesWithVehicles()
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

    private func updatePreBookingStatus() {
        if let type_ = orderType, type_ == .special {
            if isVendorOutLet {
                if let preBookingTime_ = Utilities.shared.currentOutlet?.preBookingTime, 0 < preBookingTime_ {
                    isPreBookingAvailable = true
                } else {
                    isPreBookingAvailable = false
                }
            } else {
                let userDefaults = UserDefaults.standard
                if let preBookingTime_ = userDefaults.value(forKey: preBookingDaysKey) as? Int, 0 < preBookingTime_ {
                    isPreBookingAvailable = true
                } else {
                    isPreBookingAvailable = false
                }
            }
        } else {
            if let preBookingTime_ = Utilities.shared.currentOutlet?.preBookingTime, 0 < preBookingTime_ {
                isPreBookingAvailable = true
            } else {
                isPreBookingAvailable = false
            }
        }
    }
    
    private func updateMinAndMaxDateForDelivery() {
        let currentDate: Date = Date()
        var calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
        }
        var components: DateComponents = DateComponents()
        components.calendar = calendar
        if let orderType_ = orderType, orderType_ == .normal {
            components.day = Utilities.shared.currentOutlet?.preBookingTime ?? +3
        } else {
            if isVendorOutLet {
                components.day = Utilities.shared.currentOutlet?.preBookingTime ?? +3
            } else {
                let userDefaults = UserDefaults.standard
                if let preBookingTime_ = userDefaults.value(forKey: preBookingDaysKey) as? Int {
                   components.day = preBookingTime_
                } else {
                    components.day = +3
                }
            }
        }
        let maxDate: Date = calendar.date(byAdding: components, to: currentDate) ?? Date()
        self.datePicker.minimumDate = currentDate
        self.datePicker.maximumDate = maxDate.endOfDay ?? maxDate
        self.datePicker.timeZone = TimeZone.ReferenceType.system
    }
    
    private func addSchedulePickUpPicker() {
        let datePickerBgHeight: CGFloat = self.datePickerBgView.bounds.height
        let pickerYPos = self.view.bounds.height - datePickerBgHeight
        self.datePickerBgView.frame = CGRect.init(x: 0, y: pickerYPos, width: self.view.bounds.width, height: datePickerBgHeight)
        view.addSubview(self.datePickerBgView)
        self.datePickerBgView.isHidden = true
    }
    
// MARK: - Support Methods
    
    @objc func makeOrder() {
        
        if false == Utilities.isWaselDeliveryOpen() {
            return
        }
        guard isOutletOpen() == true else {
            return
        }
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        // Uncomment the below code for minimum order feature
//        if false == validateMinmumOrderValue() {
//            return
//        }
        
        var items = [[String: AnyObject]]()
        
        var orderObject: [String: Any] = [
            OrderChargeKey: costStructure.orderCost,
            DiscountAmountKey: costStructure.discount,
            TipAmountKey: costStructure.tip,
            GrandTotalKey: costStructure.grandTotal,
            PaymentModeKey: self.paymentsMode.selectedMode.rawValue,
            OrderTypeKey: orderType?.rawValue ?? "NORMAL",
            IsRepeatKey: shouldRepeatOrder,
            cartId: Utilities.shared.cartId ?? ""
        ]

        let outlet = self.outlet ?? Utilities.shared.currentOutlet
        let handlingFee = outlet?.handleFee ?? 0
        if handlingFee > 0 {
            orderObject[HandlingFeePercent] = handlingFee
            orderObject[HandlingFeeType] = outlet?.handleFeeType ?? ""
        } else if !(outlet?.isPartnerOutLet ?? false) {
            orderObject[HandlingFeePercent] = Utilities.shared.appSettings?.handleFee ?? 0
            orderObject[HandlingFeeType] = Utilities.shared.appSettings?.handleFeeType ?? ""
        }
        orderObject[HandlingFee] = costStructure.handlingFee(outlet: outlet)
        orderObject[VehicleTypeKey] = self.vehicleType?.rawValue ?? VehicleType.motorbike.rawValue
        
        if let orderType_ = orderType, orderType_ == .special {
            if let specialOrder_ = specialOrder {
                items = specialOrder_.items as [[String: AnyObject]]
                if let address_ = specialOrder_.location {
                    if let location_ = address_.location {
                        orderObject[PickUpLocation] = location_
                    }
                    if let latitude_ = address_.latitude {
                        orderObject[LatitudeKey] = latitude_
                    }
                    if let longitude_ = address_.longitude {
                        orderObject[LongitudeKey] = longitude_
                    }
                }
                orderObject[OrderInstructionsKey] = specialOrder_.instructions
            }
            orderObject[DeliveryChargeKey] = costStructure.deliveryCharge
        } else {
            items = Utilities.getOrderItemsDictionary()
            orderObject[OrderInstructionsKey] = Utilities.shared.cart.instructions
        }
        
        orderObject[ItemsKey] = items
        if let date_ = Utilities.shared.cart.deliveryDate {
            orderObject[ScheduledDateKey] = Double(floor(date_.timeIntervalSince1970) * 1000)
        } else {
            orderObject[ScheduledDateKey] = 0
        }
        
        orderObject[TipAmountKey] = costStructure.tip

        if let user_ = Utilities.getUser() {
            
            var userObj = [String: Any]()
            
            if let id_ = user_.id {
                userObj[IdKey] = id_
            }
            if let name_ = user_.name {
                userObj[NameKey] = name_
            }
            if let phone_ = user_.mobile {
                userObj[PhoneNumberKey] = phone_
            }
            if let email_ = user_.email {
                userObj[EmailKey] = email_
            }
            orderObject[UserKey] = userObj
        }
        
        if let outlet_ = Utilities.shared.currentOutlet, let orderType_ = orderType, orderType_ == .normal {
            let outletName = Utilities.fetchOutletName(outlet_)
            orderObject[OutletKey] = [IdKey: outlet_.id ?? 0,
                                      NameKey: outletName]
            orderObject[DeliveryChargeKey] = costStructure.deliveryCharge
        } else if true == isVendorOutLet {
            if let outlet_ = Utilities.shared.currentOutlet, let orderType_ = orderType, orderType_ == .special {
                let outletName = Utilities.fetchOutletName(outlet_)
                orderObject[OutletKey] = [IdKey: outlet_.id ?? 0,
                                          NameKey: outletName]
                orderObject[DeliveryChargeKey] = costStructure.deliveryCharge
            }
        } else {
            if let outlet_ = self.outlet {
                if let orderType_ = orderType, orderType_ == .special {
                    let outletName = Utilities.fetchOutletName(outlet_)
                    orderObject[OutletKey] = [IdKey: outlet_.id ?? 0,
                                              NameKey: outletName]
                    orderObject[DeliveryChargeKey] = costStructure.deliveryCharge
                }
            }
        }
        
        if let selectedCoupon_ = selectedCoupon, let orderType_ = orderType, orderType_ == .normal {
            if let id_ = selectedCoupon_.id {
                orderObject[CouponKey] = [IdKey: id_, CodeKey: selectedCoupon_.code ?? ""]
            }
        }
        
        let addressId = addresses?[selectedAddressIndex].id ?? 0
        let addressType = addresses?[selectedAddressIndex].addressType ?? ""
        orderObject[ShippingAddressKey] = [IdKey: addressId, AddressTypeKey: addressType]
        
        if self.paymentsMode.selectedMode == .creditCard { // place order only after making the payment
            navigateToPayTabsSdk(orderObject)
        } else {
            placeOrder(orderObject)
        }
    }
    
    private func validateMinmumOrderValue() -> Bool {
        
        func checkMinmumOrderValue(outlet_: Outlet) -> Bool {
            if 0 < Utilities.getOrderItemsDictionary().count {
                if let minimumOrderCharge_ = outlet_.minimumOrderValue {
                    if costStructure.orderCost <= minimumOrderCharge_ {
                        Utilities.showToastWithMessage("Total order items cost should be greater than Minimum order value", position: .middle)
                        return false
                    }
                }
            }
            return true
        }
        
        if let outlet_ = Utilities.shared.currentOutlet, let orderType_ = orderType, orderType_ == .normal {
            if false == checkMinmumOrderValue(outlet_: outlet_) {
                return false
            }
        } else if true == isVendorOutLet {
            if let outlet_ = Utilities.shared.currentOutlet, let orderType_ = orderType, orderType_ == .special {
                if false == checkMinmumOrderValue(outlet_: outlet_) {
                    return false
                }
            }
        } else {
            if let outlet_ = self.outlet {
                if false == checkMinmumOrderValue(outlet_: outlet_) {
                    return false
                }
            }
        }
        return true
    }
    
    func configurePaymethods() {
        var aOutlet_ = Utilities.shared.currentOutlet
        if let aOutlet = self.outlet {
            aOutlet_ = aOutlet
        }
        if nil == aOutlet_ {
            paymentsMode.paymentModeEnumDictionary = []
            let userDefaults = UserDefaults.standard

//            if let isEnabledMasterCardPayment = userDefaults.value(forKey: isEnabledMasterCardPayment) as? Bool, true == isEnabledMasterCardPayment {
//                paymentsMode.paymentModeEnumDictionary.append(.masterCard)
//            }

            if let isEnabledCreditCard = userDefaults.value(forKey: isEnabledCreditCardPayment) as? Bool, true == isEnabledCreditCard {
                paymentsMode.paymentModeEnumDictionary.append(.creditCard)
            }
            if let isEnabledCreditBenfitPayment = userDefaults.value(forKey: isEnabledCreditBenfitPayment) as? Bool, true == isEnabledCreditBenfitPayment {
                paymentsMode.paymentModeEnumDictionary.append(.benfit)
            }
            if let isEnabledCashOrCard = userDefaults.value(forKey: isEnabledCashOrCardPayment) as? Bool, true == isEnabledCashOrCard {
                paymentsMode.paymentModeEnumDictionary.append(.cashOrCard)
            }



            paymentsMode.selectedMode = paymentsMode.paymentModeEnumDictionary.first ?? .cashOrCard
        } else {
            paymentsMode.paymentModeEnumDictionary = []
//            if true == aOutlet_?.isMasterCardPaymentEnabled {
//                paymentsMode.paymentModeEnumDictionary.append(.masterCard)
//            }
            if true == aOutlet_?.isCreditCardPaymentEnabled {
                paymentsMode.paymentModeEnumDictionary.append(.creditCard)
            }
            if true == aOutlet_?.isBenfitPaymentEnabled {
                paymentsMode.paymentModeEnumDictionary.append(.benfit)
            }
            if true == aOutlet_?.isCashOrCardPaymentEnabled {
                paymentsMode.paymentModeEnumDictionary.append(.cashOrCard)
            }
            paymentsMode.selectedMode = paymentsMode.paymentModeEnumDictionary.first ?? .cashOrCard
        }
        
        let userDefaults = UserDefaults.standard
        if let slectedPaymentMethod_ = userDefaults.object(forKey: slectedPaymentMethod) as? String {
            if slectedPaymentMethod_ == PaymentMode.cashOrCard.rawValue {
                paymentsMode.selectedMode = .cashOrCard
            } else if slectedPaymentMethod_ == PaymentMode.benfit.rawValue {
                paymentsMode.selectedMode = .benfit
            } else if slectedPaymentMethod_ == PaymentMode.creditCard.rawValue {
                paymentsMode.selectedMode = .creditCard
            } else if slectedPaymentMethod_ == PaymentMode.masterCard.rawValue {
                paymentsMode.selectedMode = .masterCard
            } else {
                paymentsMode.selectedMode = paymentsMode.paymentModeEnumDictionary.first ?? .cashOrCard
            }
        }
        
        self.paymentModeTableView.reloadData()
    }
    
    private func isOutletOpen() -> Bool {
        
        if let orderType_ = orderType, orderType_ == .normal, let outlet_ = Utilities.shared.currentOutlet {
            
            let outletStatus = Utilities.isOutletOpen(outlet_)
            let message = "OOPS!! looks like outlet is closed, please try again later."
            
            if outletStatus.isOpen == false {
                Utilities.showToastWithMessage(message)
            }
            return outletStatus.isOpen
        }
        return true
    }
    
    private func processUnconfirmedOrder(_ removedItems: [OutletItem]) {
        
        let i = removedItems.map({ (outletItem) -> Int in
            return outletItem.id ?? 0
        }).compactMap { $0 }
        
        for item_ in Utilities.shared.cart.cartItems {
            if i.contains(item_.id ?? 0) == true {
                Utilities.shared.cart.cartItems.removeObject(object: item_)
            }
        }
    }

    private func showOrderCancelAlert() {
        
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "All the items in this order are not available right now.", buttonText: nil, cancelButtonText: "Ok")
        responder.setCancelButtonColor(.white)
        responder.setCancelTitleColor(.unSelectedTextColor())
        responder.setCancelButtonBorderColor(.unSelectedTextColor())
        responder.addCancelAction({
            self.cancelOrder()
        })
    }

    private func showUnprocessedOrderAlert(removedItems: [OutletItem]) {
        
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "Some of the items in your order are not available right now. Would you like to proceed?", buttonText: "No", cancelButtonText: "Yes")
        
        responder.addCancelAction({
            DispatchQueue.main.async(execute: {
                Utilities.showHUD(to: self.view, "")
                self.processUnconfirmedOrder(removedItems)
                self.loadOrderCostDetails()
                self.confirmOrderTableView.reloadData()
                self.reloadDriverTipView()
                self.reloadCostDetailTable()
                self.done(nil)
            })
        })
        
        responder.addAction({
            self.cancelOrder()
        })
    }

    private func cancelOrder() {
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let navController = appDelegate.window?.rootViewController as? UINavigationController {
                if let tabController = navController.viewControllers.first as? TabBarController {
                    Utilities.shouldHideTabCenterView(tabController, false)
                    if let homeNavController = tabController.viewControllers?.first as? UINavigationController {
                        let homeController = homeNavController.viewControllers[0]
                        homeNavController.setViewControllers([homeController], animated: true)
                        
                        DispatchQueue.main.async(execute: {
                            self.clearSavedCart()
                            self.navigationController?.dismiss(animated: true, completion: nil)
                        })
                    }
                }
            }
        }
    }
    
    @objc fileprivate func dismissPaymentView(_ sender: Any?) {
        
        if view.subviews.contains(couponSuccessView) == true {
            
            couponSuccessView.removeFromSuperview()
            self.dimView.isUserInteractionEnabled = false
            self.dimView.backgroundColor = .clear
            return
        }
        
        paymentModeTableView.isHidden = true
        paymentViewBottomConstraint.constant = -(1.5*self.viewHeight)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn], animations: {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.dimView.isUserInteractionEnabled = false
            self.dimView.backgroundColor = .clear
        }, completion: nil)
    }
    
    private func formPickUplocationObject() -> [String: AnyObject] {
        
        var pickUpLocationObject = [String: AnyObject]()
        let userId = Utilities.shared.user?.id ?? ""
        pickUpLocationObject[UserIdKey] = userId as AnyObject
        
        if let orderType_ = orderType, orderType_ == .normal {
            if let outlet_ = Utilities.shared.currentOutlet, let address = outlet_.address, let outletId = outlet_.id {
                pickUpLocationObject[LatitudeKey] = address.latitude as AnyObject
                pickUpLocationObject[LongitudeKey] = address.longitude as AnyObject
                pickUpLocationObject["outletId"] = outletId as AnyObject
            }
        } else {
            let latitude = specialOrder?.location?.latitude ?? 0.0
            let longitude = specialOrder?.location?.longitude ?? 0.0
            pickUpLocationObject[LatitudeKey] = latitude as AnyObject
            pickUpLocationObject[LongitudeKey] = longitude as AnyObject
            if let outletId = (Utilities.shared.currentOutlet ?? outlet)?.id, orderType == .special {
                pickUpLocationObject["outletId"] = outletId as AnyObject
            }
        }

        if let isPartner = (Utilities.shared.currentOutlet ?? outlet)?.isPartnerOutLet {
            pickUpLocationObject["type"] = (isPartner ? OrderType.normal.rawValue : OrderType.special.rawValue) as AnyObject
        } else {
            pickUpLocationObject["type"] = (orderType?.rawValue ?? OrderType.special.rawValue) as AnyObject
        }
        return pickUpLocationObject
    }
    
    private func castAddress() {
        
        if let addresses_ = self.addresses {
            let castedAddresses = addresses_.filter { $0.castOff == true }
            if castedAddresses.count == 1 {
                for (index, address_) in addresses_.enumerated() where address_.castOff == true {
                    self.addresses?.remove(at: index)
                    self.addresses?.insert(address_, at: 0)
//                    if let deliveryCharge_ = address_.deliveryCharge {
//                        self.costStructure.deliveryCharge = deliveryCharge_
//                    }
                    break
                }
            } else {
                if var addresses_ = self.addresses, var first = addresses_.first {
                    first.castOff = true
//                    if let deliveryCharge_ = first.deliveryCharge {
//                        self.costStructure.deliveryCharge = deliveryCharge_
//                    }
                    addresses_[0] = first
                    self.addresses = addresses_
                }
            }
        }
    }
    
    fileprivate func loadOrderCostDetails() {
        
        costStructure.orderCost = Utilities.shared.getTotalCost()
//        if 0 < costStructure.deliveryCharge {
//            grandTotalLabel.text = "\(String(format: "%.3f", costStructure.orderCost + costStructure.tip + costStructure.deliveryCharge - costStructure.discount))"
//        } else {
//            grandTotalLabel.text = "\(String(format: "%.3f", costStructure.orderCost + costStructure.tip - costStructure.discount))"
//        }
//
//        if let outlet_ = Utilities.shared.currentOutlet, true == outlet_.isFleetOutLet{
//            grandTotalLabel.text = "\(String(format: "%.3f", costStructure.orderCost + costStructure.tip - costStructure.discount))"
//        }
//        else if (true == isVendorOutLet) {
//            if let outlet_ = Utilities.shared.currentOutlet, true == outlet_.isFleetOutLet{
//                grandTotalLabel.text = "\(String(format: "%.3f", costStructure.orderCost + costStructure.tip - costStructure.discount))"
//            }
//        }

        let handlingFee = costStructure.handlingFee(outlet: self.outlet ?? Utilities.shared.currentOutlet)
        if isFreeDelivery == 1{
            costStructure.deliveryCharge = 0.000
        }
        if 0 < costStructure.deliveryCharge {
            if let outlet_ = outlet, true == outlet_.isFleetOutLet {
                grandTotalLabel.text = "\(String(format: "%.3f", costStructure.orderCost + costStructure.tip + costStructure.deliveryCharge + handlingFee - costStructure.discount))"
            } else if let outlet_ = Utilities.shared.currentOutlet, true == outlet_.isFleetOutLet {
                grandTotalLabel.text = "\(String(format: "%.3f", costStructure.orderCost + costStructure.tip + costStructure.deliveryCharge + handlingFee - costStructure.discount))"
            } else {
                grandTotalLabel.text = "\(String(format: "%.3f", costStructure.orderCost + costStructure.tip + costStructure.deliveryCharge + handlingFee - costStructure.discount))"
            }
        } else {
            grandTotalLabel.text = "\(String(format: "%.3f", costStructure.orderCost + costStructure.tip + handlingFee - costStructure.discount))"
        }
        
//        if Utilities.shared.isSmallDevice == true {
            granTotalView.isHidden = expandCollapseButton.isSelected
            billDetailsView.isHidden = !expandCollapseButton.isSelected
//        } else {
//            granTotalView.isHidden = true
//            billDetailsView.isHidden = false
//        }
    }
    
    private func sendConfirmOrderEventToUpshot(_ order_: Order) {
        let addressType = order_.shippingAddress?.addressType ?? ""
        let couponId = order_.coupon?.id ?? 0
        let tipAmount = order_.tipAmount ?? 0.0
        let charge = order_.charge ?? 0.0
        let deliveryCharge = order_.deliveryCharge ?? 0.0
        let totalCharge = order_.grandTotal ?? 0.0
        let paymentType = (order_.paymentType ?? "").uppercased()
        let orderId = order_.id ?? 0
        // EEE, dd MMM yyyy, hh:mm a
        let scheduledDateString = Utilities.getSystemDateString(date: order_.scheduledDate, "dd/MM/yy, hh:mm a")
        let isScheduledDateEnbled = !scheduledDateString.isEmpty
        let ownDelivery = order_.outlet?.isFleetOutLet ?? false
        let reOrderString = (true == self.shouldRepeatOrder) ? "Yes" : "No"
        var outletType = "Partner"
        if self.isVendorOutLet {
            outletType = "Vendor"
        } else  if let orderType_ = orderType, orderType_ == .special {
            outletType = "OrderAnything"
        }
        
        var params: [String: Any] = [
            "AddressType": addressType,
            "PaymentType": paymentType,
            "ScheduledDelivery": isScheduledDateEnbled ? "Yes" : "No",
            "OwnDelivery": ownDelivery ? "Yes" : "No",
            "ReOrder": reOrderString,
            "Type": outletType,
            "ScheduledeliveryTime": scheduledDateString,
            "CartID": Utilities.shared.cartId ?? ""
        ]
        if 0 < couponId {
            params["CouponStatus"] = "Success"
            if let couponCode = order_.coupon?.code, false == couponCode.isEmpty {
                params["CouponCode"] = couponCode
            }
        }
        if 0 < tipAmount {
            params["Tip"] = tipAmount
        }
        if 0 < charge {
            params["OrderCharge"] = charge
        }
        if 0 < deliveryCharge {
            params["DeliveryCharge"] = deliveryCharge
        }
        if 0 < totalCharge {
            params["TotalCharge"] = totalCharge
        }
        if let orderStatus = order_.status?.rawValue {
            params["Status"] = orderStatus
        }
        UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CONFIRMORDER_EVENT, params: params)
        sendOrderItemsEventToUpshot(order_)
    }
    
    func sendOrderItemsEventToUpshot(_ order_: Order) {
        let orderId = order_.id ?? 0
        var aOutlet_: Outlet?
        if let outlet_ = Utilities.shared.currentOutlet, let orderType_ = orderType, orderType_ == .normal {
            aOutlet_ = outlet_
        } else if true == isVendorOutLet {
            if let outlet_ = Utilities.shared.currentOutlet, let orderType_ = orderType, orderType_ == .normal {
                aOutlet_ = outlet_
            } else if let outlet_ = self.outlet {
                aOutlet_ = outlet_
            }
        } else {
            if let outlet_ = self.outlet {
                if let orderType_ = orderType, orderType_ == .normal {
                    aOutlet_ = outlet_
                }
            }
        }
        
        if let orderItems_ = order_.items {
            for orderItem in orderItems_ {
                if let outLetInfo_ = aOutlet_ {
                    var params: [String: Any] = [
                        "Qty": orderItem.quantity ?? 0,
                        "Charge": orderItem.price ?? 0.0,
                        "OrderID": String(orderId),
                        "CartID": Utilities.shared.cartId ?? ""
                    ]
                    if let outletName = outLetInfo_.name, false == outletName.isEmpty {
                        params["StoreName"] = outletName
                        params["StoreID"] = String(outLetInfo_.id ?? 0) 
                        
                        if let categoryId = outLetInfo_.amenity?.id {
                            params["CategoryID"] = categoryId
                        }
                        if let categoryName = outLetInfo_.amenity?.name, false == categoryName.isEmpty {
                            params["CategoryName"] = categoryName
                        }
                        if let outletItems_ = outLetInfo_.outletItems, let orderItems_ = order_.items {
                            let orderIds = orderItems_.map { $0.itemId }.compactMap { $0 }
                            _ = outletItems_.filter({ (item) -> Bool in
                                if orderIds.contains(item.id ?? 0) {
                                    if let subCategoryId = item.itemCategory?.id {
                                        params["SubCategoryID"] = String(subCategoryId)
                                    }
                                    if let itemCategoryName = item.itemCategory?.name {
                                        params["SubCategoryName"] = itemCategoryName
                                    }
                                }
                                return false
                            })
                        }
                    }
                    
                    if let itemName = orderItem.name, false == itemName.isEmpty {
                        params["ItemName"] = itemName
                        params["ItemID"] = String(orderItem.id ?? 0)
                    }
                    UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.ORDERITEMS_EVENT, params: params)
                }
            }
        }
    }
    
    private func showOrderSuccesView(_ order_: Order) {
        self.sendConfirmOrderEventToUpshot(order_)
        if #available(iOS 10.0, *) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        paymentModeTableView.isHidden = true
        self.dimView.isUserInteractionEnabled = false
        self.paymentViewBottomConstraint.constant = -(1.5*self.viewHeight)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn], animations: { () -> Void in
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }, completion: { (_: Bool) -> Void in
            self.doneViewBottomConstraint.constant = 0.0
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn], animations: { () -> Void in
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }, completion: { (_: Bool) -> Void in
                self.proceedToOrderDetails(order_)
            })
        })
    }

    private func proceedToOrderDetails(_ order_: Order) {
        
        let dispatchTime = DispatchTime.now() + .seconds(2)
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            if false == self.shouldRepeatOrder {
                UPSHOTActivitySetup.shared.closeEvent(eventId: BKConstants.VIEW_STORE_ORDER_EVENT)
            } else {
                let params: [String: Any] = [
                    "OrderID": String(order_.id ?? 0),
                    "CartID": Utilities.shared.cartId ?? ""
                ]
                UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.REORDER_EVENT, params: params)
            }
            self.clearSavedCart()
            
            let storyboard = Utilities.getStoryBoard(forName: .orderHistory)
            if let orderDetailsController = storyboard.instantiateViewController(withIdentifier: "OrderDetailsController") as? OrderDetailsController {
                orderDetailsController.orderId = order_.id ?? 0
                orderDetailsController.shouldPopBack = false
                orderDetailsController.isVendorOutLet = self.isVendorOutLet
                self.navigationController?.pushViewController(orderDetailsController, animated: true)
            }
        }
    }
    
    func clearSavedCart() {
        
        Utilities.shared.clearCart(isManualClear: true)
        if self.shouldRepeatOrder || isVendorOutLet {
            Utilities.shared.currentOutlet = nil
        }
        Utilities.shared.reloadCartView()
    }

    func removeSpecialCharsFromString(text: String) -> String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890-")
        return text.filter {okayChars.contains($0) }
    }
}

// MARK: - UITableView Delegates and Datasources
extension ConfirmOrderController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == paymentModeTableView {
            return 1
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch tableView {
        case paymentModeTableView:
            return paymentsMode.paymentModeEnumDictionary.count
        case confirmOrderTableView:
            var numberOfRows: Int = 0
            if let type_ = orderType, type_ == .special {
                numberOfRows = isPreBookingAvailable ? 3 : 2
            } else {
                numberOfRows = isPreBookingAvailable ? 4 : 3
            }
            return numberOfRows
        case costDetailTableView:
            var costDetailsRowCount = 3 // Order charge, Delivery charge, grand total
            if shouldDisplayHandlingFee() {
                costDetailsRowCount += 1 // Handle Fee
            }
            var rows = expandCollapseButton.isSelected ? costDetailsRowCount : 0
            if expandCollapseButton.isSelected {
                rows += (costStructure.discount > 0) ? 1 : 0
                rows += (costStructure.tip > 0) ? 1 : 0
            }
            return rows
        default:
            return 0
        }
    }

    func shouldDisplayHandlingFee() -> Bool {
        let outlet = self.outlet ?? Utilities.shared.currentOutlet
        if (outlet?.handleFee ?? 0) > 0 {
            return true
        } else if !(outlet?.isPartnerOutLet ?? false) {
            return (Utilities.shared.appSettings?.handleFee ?? 0) > 0
        }
        return false
    }

    func schedulePickTimeCell(forRowAt indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let schedulePickTimeCell = tableView.dequeueReusableCell(withIdentifier: SchedulePickTimeCell.cellIdentifier(), for: indexPath) as? SchedulePickTimeCell else {
            return UITableViewCell()
        }
        schedulePickTimeCell.pickupTimeDelegate = self
        if let date_ = Utilities.shared.cart.deliveryDate {
            datePicker.setDate(date_, animated: false)
        }
        schedulePickTimeCell.updatePickUpTimeText()
        return schedulePickTimeCell
    }

    func addressCell(forRowAt indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.cellIdentifier(), for: indexPath) as? AddressCell else {
            return UITableViewCell()
        }
        cell.addressDelegate = self
        return cell
    }

    func couponCell(forRowAt indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CouponDetailCell.cellIdentifier(), for: indexPath) as? CouponDetailCell else {
            return UITableViewCell()
        }
        cell.couponDelegate = self
        cell.loadCellWithCoupon(coupon: selectedCoupon)
        return cell
    }

    func carouselCell(forRowAt indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CarouselCell.cellIdentifier(), for: indexPath) as? CarouselCell else {
            return UITableViewCell()
        }

        cell.carousel.reloadData()
        cell.carousel.scrollToItem(at: self.selectedAddressIndex, animated: false)
        return cell
    }

    func paymentModeCell(forRowAt indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PaymentModeTableViewCell.cellIdentifier()) as? PaymentModeTableViewCell else {
            return UITableViewCell()
        }
        let paymentMode = paymentsMode.paymentModeEnumDictionary[indexPath.row]

        var aOutlet_ = Utilities.shared.currentOutlet
        if let aOutlet = self.outlet {
            aOutlet_ = aOutlet
        }
        cell.loadCellWithContent(isSelectedMode: (paymentsMode.selectedMode == paymentMode), paymentMode: paymentMode, aOutlet_: aOutlet_)
        return cell
    }

    func costDetailCell(forRowAt indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CostDetailCell.cellIdentifier(), for: indexPath) as? CostDetailCell else {
            return UITableViewCell()
        }

        var _outlet: Outlet?
        if let outlet = Utilities.shared.currentOutlet, orderType == .normal {
            _outlet = outlet
        } else if let outlet = self.outlet, (isVendorOutLet || orderType == .normal) {
            _outlet = outlet
        }
        let grandTotalIndex = costStructure.getGrandTotalIndex()
        let isGrandTotalCell = (grandTotalIndex == indexPath.row)

        cell.loadCost(costStruct: costStructure, index: indexPath.row, outlet: _outlet, isGrandTotal: isGrandTotalCell)
        return cell
    }

    func confirmOrderTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return carouselCell(forRowAt: indexPath, in: tableView)
        case 1:
            if isPreBookingAvailable {
                return schedulePickTimeCell(forRowAt: indexPath, in: tableView)
            } else {
                return addressCell(forRowAt: indexPath, in: tableView)
            }
        case 2:
            if isPreBookingAvailable {
                return addressCell(forRowAt: indexPath, in: tableView)
            } else {
                return couponCell(forRowAt: indexPath, in: tableView)
            }
        case 3:
            return couponCell(forRowAt: indexPath, in: tableView)
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case paymentModeTableView:
            return paymentModeCell(forRowAt: indexPath, in: tableView)
        case confirmOrderTableView:
            return confirmOrderTableView(tableView, cellForRowAt: indexPath)
        case costDetailTableView:
            return costDetailCell(forRowAt: indexPath, in: tableView)
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.paymentModeTableView == tableView {
            if #available(iOS 10.0, *) {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            }
            paymentsMode.selectedMode = paymentsMode.paymentModeEnumDictionary[indexPath.row]
            self.selectedPaymentMode = paymentsMode
            
            let userDefaults = UserDefaults.standard
            userDefaults.set(paymentsMode.selectedMode.rawValue, forKey: slectedPaymentMethod)
            userDefaults.synchronize()

            self.paymentModeTableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == costDetailTableView {
            return sectionView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == costDetailTableView {
            return 60
        }
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case confirmOrderTableView:
            switch indexPath.row {
            case 0: return 251
            case 1: return 60
            case 2: return 55
            default: return 70
            }
        case costDetailTableView:
            return UITableView.automaticDimension
        default:
            return UITableView.automaticDimension
        }
    }

}

// MARK: - iCarasousel Delegates and Datasources
extension ConfirmOrderController: iCarouselDataSource, iCarouselDelegate {

    func numberOfItems(in carousel: iCarousel) -> Int {
        if let addresses_ = addresses, addresses_.count > 0 {
            return addresses_.count
        }
        return 0
    }

    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {

        if let addresses_ = addresses {
            let address = addresses_[index]
            if address.castOff == true {
                selectedAddressIndex = index
            }
            let itemView = AddressView(frame: CGRect(x: 0.0, y: 0.0, width: 260.0, height: 0.0))
            itemView.loadAddress(with: address)

            var frame = itemView.frame
            frame.size.height = carousel.frame.size.height
            itemView.frame = frame
            return itemView
        }
        return UIView()
    }

    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        deselectAllAddresses()
        if var item = addresses?[index] {
            item.castOff = true
            addresses?[index] = item
        }

//        if let deliveryCharge_ = addresses?[index].deliveryCharge {
//            self.costStructure.deliveryCharge = deliveryCharge_
//            loadOrderCostDetails()
//        }
//        UIView.performWithoutAnimation {
//            confirmOrderTableView.reloadData()
//            reloadCostDetailTable()
//        }
        selectedAddressIndex = index
        getDeliveryChargesWithVehicles()
    }

    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {

        if carousel.currentItemIndex != -1 && carousel.currentItemIndex != selectedAddressIndex {
            deselectAllAddresses()
            if var item = addresses?[carousel.currentItemIndex] {
                item.castOff = true
                addresses?[carousel.currentItemIndex] = item
            }
            selectedAddressIndex = carousel.currentItemIndex

            getDeliveryChargesWithVehicles()
            
//            if let deliveryCharge_ = addresses?[selectedAddressIndex].deliveryCharge {
//                self.costStructure.deliveryCharge = deliveryCharge_
//                loadOrderCostDetails()
//            }
//            UIView.performWithoutAnimation {
//                confirmOrderTableView.reloadData()
//                reloadCostDetailTable()
//            }
        }
    }
    
    private func getDeliveryChargesWithVehicles() {
        if Utilities.getUser() != nil {
            Utilities.showHUD(to: self.view, "")
            var requestObj: [String: Any] = [:]
            guard let addresses = self.addresses, addresses.count > 0 else {
                UIView.performWithoutAnimation {
                    reloadViews()
                }
                return
            }
            var index = selectedAddressIndex
            if index < 0 {
                index = 0
            }
            
            guard let orderType = self.orderType else {
                reloadViews()
                return
            }
            
            if let outlet_ = Utilities.shared.currentOutlet, let outletAddress = outlet_.address {
                requestObj["outletLatitude"] = outletAddress.latitude ?? 0.0
                requestObj["outletLongitude"] = outletAddress.longitude ?? 0.0
            } else if orderType == .special { // No outlet specified, it's a custom order anything location
                requestObj["outletLatitude"] = self.specialOrder?.location?.latitude ?? 0.0
                requestObj["outletLongitude"] = self.specialOrder?.location?.longitude ?? 0.0
            } else {
                reloadViews()
                return
            }
            
            requestObj["latitude"] = addresses[index].latitude ?? 0.0
            requestObj["longitude"] = addresses[index].longitude ?? 0.0
            requestObj["orderType"] = orderType.rawValue
            
            ApiManager.shared.apiService.deliveryChargesByVehicleType(requestObj as [String: AnyObject]).subscribe(
                onNext: { [weak self](deliveryChargeObj) in
                    Utilities.hideHUD(from: self?.view)
                    if let vehicleType = self?.vehicleType {
                        switch vehicleType {
                        case .motorbike: self?.costStructure.deliveryCharge = deliveryChargeObj.bikeDeliveryCharge ?? 0.0
                        case .car: self?.costStructure.deliveryCharge = deliveryChargeObj.carDeliveryCharge ?? 0.0
                        case .truck: self?.costStructure.deliveryCharge = deliveryChargeObj.truckDeliveryCharge ?? 0.0
                        }
                    }
                    
                    UIView.performWithoutAnimation {
                        self?.reloadViews()
                    }
                }, onError: { [weak self](error) in
                    Utilities.hideHUD(from: self?.view)
                    if let error_ = error as? ResponseError {
                        if error_.getStatusCodeFromError() == .accessTokenExpire {

                        } else {
                            Utilities.showToastWithMessage(error_.description())
                        }
                    }
            }).disposed(by: disposableBag)
        }
    }
    
    private func reloadViews() {
        Utilities.hideHUD(from: self.view)
        self.confirmOrderTableView.reloadData()
        self.reloadCostDetailTable()
        self.loadOrderCostDetails()
        self.reloadDriverTipView()
    }

    fileprivate func deselectAllAddresses() {
        if let addresses_ = addresses {
            for (index, item) in addresses_.enumerated() {
                var newItem = item
                newItem.castOff = false
                addresses?[index] = newItem
            }
        }
    }

    func addNewAddress(with address: Address) {
        self.selectedAddressIndex = 0
        getAddresses()
    }
}

// MARK: - Apply Coupon Delegate Methods
extension ConfirmOrderController: ApplyCouponDelegate {
    
    func couponAppliedWithCoupon(coupon: Coupon?) {
        if let coupon_ = coupon {
            let orderCost = Utilities.shared.getTotalCost()
            if let minOrderValue_ = coupon_.minOrderValue {
                guard orderCost >= minOrderValue_ else {
                    selectedCoupon = nil

                    let attString = formAttStringForText(text: "This coupon can only be applied for order value above ", amount: minOrderValue_, font: UIFont.montserratRegularWithSize(16.0), fontColor: UIColor.unSelectedTextColor())
                    showAlertWithAmount(attText: attString, color: .alertColor())
                    if #available(iOS 10.0, *) {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }
                    return
                }
            }
            
            selectedCoupon = coupon_
            if selectedCoupon?.offerType == .percentageBased {
                if let percentage_ = selectedCoupon?.percentageValue {
                    discountAmount = (orderCost * percentage_) / 100.0
                    if let discount_ = selectedCoupon?.discountAmount {
                        discountAmount = min(min(discountAmount, discount_), orderCost)
                    }
                }
            } else {
                if let discount_ = selectedCoupon?.discountAmount {
                    discountAmount = min(discount_, orderCost)
                }
            }
            costStructure.discount = discountAmount
            showCouponSuccessView()
            loadOrderCostDetails()
            confirmOrderTableView.reloadData()
            reloadDriverTipView()
            reloadCostDetailTable()
        }
    }
    
    fileprivate func formAttStringForText(text: String, amount: Double, font: UIFont, fontColor: UIColor) -> NSMutableAttributedString {
        
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "bDBlack")
        let width_: CGFloat = attachment.image?.size.width ?? 0.0
        attachment.bounds = CGRect(x: 0.0, y: -3.0, width: width_, height: width_)
        let attachmentString = NSAttributedString(attachment: attachment)
        let myString = NSMutableAttributedString(string: "\(text)")
        
        myString.append(attachmentString)
        
        let priceNumber = Double(amount)
        let priceText = String(format: "%.3f", priceNumber)
        let priceString = NSAttributedString(string: " \(priceText)")

        myString.append(priceString)
        let stringRange = NSRange(location: 0, length: myString.length)
        myString.addAttribute(NSAttributedString.Key.foregroundColor, value: fontColor, range: stringRange)
        myString.addAttribute(NSAttributedString.Key.font, value: font, range: stringRange)
        
        return myString
    }
    
    fileprivate func showAlertWithAmount(attText: NSMutableAttributedString, color: UIColor) {
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: nil, buttonText: nil, cancelButtonText: "OK", attText: attText)
        responder.setCancelButtonColor(.white)
        responder.setCancelTitleColor(.unSelectedTextColor())
        responder.setCancelButtonBorderColor(.unSelectedTextColor())
    }
    
    fileprivate func showCouponSuccessView() {
        self.dimView.isUserInteractionEnabled = true
        self.dimView.backgroundColor = UIColor(red: (53.0/255.0), green: (53.0/255.0), blue: (53.0/255.0), alpha: 0.7)
        let attText = formAttStringForText(text: "Coupon code applied successfully you saved ", amount: costStructure.discount, font: .montserratRegularWithSize(20.0), fontColor: UIColor.selectedTextColor())
        couponSuccessLabel.attributedText = attText
        couponSuccessView.center = view.center
        view.addSubview(couponSuccessView)
        if #available(iOS 10.0, *) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
// MARK: AddressProtocol
    
    func showAddress() {
        addNewAddress(nil)
    }
    
// MARK: SchedulePickUpTimeProtocol
    
    func showSchedulePickUpTimePicker() {
        self.datePickerBgView.isHidden = false
    }
    
// MARK: CouponProtocol
    
    func couponAction(state: Bool) {
        if state == true {
            selectedCoupon = nil
            costStructure.discount = 0.0
            loadOrderCostDetails()
            confirmOrderTableView.reloadData()
            reloadDriverTipView()
            reloadCostDetailTable()
        } else {
            applyCoupon(nil)
        }
    }
}

// MARK: - Tip collectionView Datasource and Delegate Methods
extension ConfirmOrderController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TipCollectionViewCell.cellIdentifier(), for: indexPath) as? TipCollectionViewCell else {
            return UICollectionViewCell()
        }
        let tip = tips[indexPath.item]
        cell.updateTip(tip: tip, isSelected: indexPath.item == selectedTipIndex)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item != tips.count - 1 else {
            let tip = (tips.last?.amount ?? 0).getDinams()
            tipTextField.text = tip > 0 ? "\(String(format: "%.3f", tip))" : ""

            selectedTipIndex = indexPath.item
            self.setTip()
            self.tipForDriverView.isHidden = false
            
            self.tipFils = Utilities.shared.cart.tip
            let dinams = Utilities.shared.cart.tip.getDinams()
            tipTextField.text = dinams > 0 ? "\(String(format: "%.3f", dinams))" : ""

            let headerText_ = (dinams > 0) ? NSLocalizedString("Change Tip Amount", comment: "") : NSLocalizedString("Enter Tip amount", comment: "")
            tipForDriverPopUpHeaderLabel.text = headerText_
            setTip()
            loadOrderCostDetails()
            UIView.performWithoutAnimation {
                reloadDriverTipView()
                reloadCostDetailTable()
            }
            return
        }
        guard indexPath.item != selectedTipIndex else {
            selectedTipIndex = -1
            Utilities.shared.cart.tip = 0
            self.tipFils = Utilities.shared.cart.tip
            self.setTip()
            loadOrderCostDetails()
            UIView.performWithoutAnimation {
                reloadDriverTipView()
                reloadCostDetailTable()
            }
            return
        }
        view.endEditing(true)
        selectedTipIndex = indexPath.item
        Utilities.shared.cart.tip = tips[selectedTipIndex].amount
        self.tipFils = Utilities.shared.cart.tip
        self.setTip()
        loadOrderCostDetails()
        UIView.performWithoutAnimation {
            reloadDriverTipView()
            reloadCostDetailTable()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height
        return CGSize(width: 75.0, height: height)
    }
    
}

// MARK: - Tip Testfield Delegate Methods
extension ConfirmOrderController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == tipTextField {
            let currentCharacterCount = textField.text?.count ?? 0
            if range.length + range.location > currentCharacterCount {
                return false
            }
            let newLength = currentCharacterCount + string.count - range.length
            
            let allowedCharacterSet = CharacterSet(charactersIn: "0123456789.")
            
            let newCharacters = CharacterSet(charactersIn: string)
            let isValidCharacter = allowedCharacterSet.isSuperset(of: newCharacters)
            
            var alreadyFloat = false
            if let text_ = textField.text, string == ".", text_.contains(string) {
                alreadyFloat = true
            }

            let isValidFloat = validate(string: (textField.text ?? "") + string)
            let shouldReturnKeyBoard = newLength <= 7 && isValidCharacter && !alreadyFloat && isValidFloat
            if true == shouldReturnKeyBoard {
                let text_ = (tipTextField.text ?? "") + string
                let tip = Double(text_) ?? -1
                self.tipFils = tip.getFills()
                setTip()
            }
            
            return shouldReturnKeyBoard
        }
        return true
    }
    
    func validate(string: String) -> Bool {

        let components = string.components(separatedBy: ".")
        guard components.count != 0 else { return true }
        if components.count > 0 && components.count < 3 {
            let validSet = CharacterSet.whitespacesAndNewlines
            if components.count == 1 {
                return components[0].trimmingCharacters(in: validSet).length <= MaxTipCharacters
            } else if components.count == 2 {
                let isValidNumberDigitCount = components[0].trimmingCharacters(in: validSet).length <= MaxTipCharacters
                let isValidDecimalDigitCount = components[1].trimmingCharacters(in: validSet).length <= MaxTipCharacters
                return isValidNumberDigitCount && isValidDecimalDigitCount
            } else {
                return false
            }
        }
        return true
    }
    
}

protocol SchedulePickUpTimeProtocol: class {
    func showSchedulePickUpTimePicker()
}

protocol AddressProtocol: class {
    func showAddress()
}

protocol CouponProtocol: class {
    func couponAction(state: Bool)
}
