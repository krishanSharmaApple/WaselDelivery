//
//  OrderDetailsController.swift
//  WaselDelivery
//
//  Created by sunanda on 12/5/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import Unbox

class OrderDetailsController: BaseViewController {

    @IBOutlet weak var tapgesture: UITapGestureRecognizer!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var orderTableView: UITableView!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var arrowButton: UIButton!
    @IBOutlet weak var bottomView: UIView!

    var orderId: Int!
    var shouldPopBack: Bool = false
    var isVendorOutLet: Bool = false
    
    fileprivate var order: Order?
    fileprivate var orderItems: [OrderItem]?
    fileprivate var specialOrderItems: [OrderItem]?
    fileprivate var rowCount = 6
    fileprivate var disposeObj: Disposable?
    fileprivate var disposableBag = DisposeBag()
    var orderChargeArray: [(type: String, value: Double, handleFeeType: String)] = []
    let bottomViewHeight: CGFloat = 40.0
    var lastContentOffsetY: CGFloat = 0.0
    var orderDetailsDelegate: OrderDetailsDelegate?

    enum ArrowState {
        case up // arrow button with up image and tableView with zero offSet
        case down // arrow button with down image and tableView with maximum offSet
        case none
    }

    // Holds current state of arrow button and updates UI of BottomView if required
    private var arrowButtonState: ArrowState = .down {
        didSet {
            // update UI of bottomView if newValue not equals to oldValue
            guard oldValue != arrowButtonState else { return }

            // Update bottomView in mainThread
            DispatchQueue.main.async {
                switch self.arrowButtonState {
                case .up: self.showBottomView(withUpArrow: true)
                case .down: self.showBottomView(withUpArrow: false)
                case .none: self.hideBottomView()
                }
            }
        }
    }
// MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addNavigationView()
        hideBottomView()
        navigationView?.titleLabel.text = "Order Summary" //OID\(orderId!)"
        orderTableView.register(UINib(nibName: "OrderPendingCell", bundle: nil), forCellReuseIdentifier: OrderPendingCell.cellIdentifier())
        orderTableView.register(UINib(nibName: "OrderHistoryCell", bundle: nil), forCellReuseIdentifier: OrderHistoryCell.cellIdentifier())
        orderTableView.register(UINib(nibName: "OrderHistoryPendingCell", bundle: nil), forCellReuseIdentifier: OrderHistoryPendingCell.cellIdentifier())
        
        orderTableView.estimatedRowHeight = 330.0
        orderTableView.rowHeight = UITableView.automaticDimension
//        tapgesture.isEnabled = false
        orderTableView.tableHeaderView?.frame.size.height = 0.0
        
//        if let nc = self.navigationController,
//            nc.viewControllers.count == 2,
//            nc.viewControllers[0].isKind(of: OrderHistoryController.self) {
            self.navigationView?.backButton.isHidden = true
            self.navigationView?.editButton.isHidden = false
            self.navigationView?.editButton.setImage(#imageLiteral(resourceName: "orderHistoryCollapse"), for: .normal)
            self.navigationView?.editButton.setTitle("", for: .normal)
//        }
        self.view.clipsToBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hiding the tabbar center view
        if let tabC_ = tabBarController as? TabBarController {
            tabC_.centerView?.isHidden = true
        }
        navigationHeightConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
        self.tabBarController?.tabBar.isHidden = true
        getDetails(isRefresh: false, isSilentCall: false)
        startAnimationTimer()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDetails(_:)), name: NSNotification.Name(RefreshOrderDetailsNotification), object: nil)
        Utilities.removeTransparentView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Utilities.shared.cancelTimer()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(RefreshOrderDetailsNotification), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.ORDER_SUMMARY_SCREEN)
    }

    override func navigateBack(_ sender: Any?) {
        self.tabBarController?.tabBar.isHidden = false
        // UnHiding the tabbar center view
        if let tabC_ = tabBarController as? TabBarController {
            tabC_.centerView?.isHidden = false
        }
        if shouldPopBack == true {
            Utilities.shouldHideTabCenterView(tabBarController, false)
            _ = self.navigationController?.popViewController(animated: true)
        } else {
            dismiss()
        }
        orderDetailsDelegate?.changedOrderInfo()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

// MARK: - Notificaion Methods
    
    func getDetails(isRefresh: Bool, isSilentCall: Bool) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        getOrderDetails(orderId: orderId ?? 0, isSilentCall: isSilentCall).subscribe(onNext: { (order_) in
            self.order = order_
            self.reloadDetailsData(isRefresh: isRefresh)
        }).disposed(by: disposableBag)
    }
    
    @objc private func refreshDetails(_ notification: Notification) {
        
        let userInfo = notification.userInfo
        if let userInfo_ = userInfo {
            if let notificationId_ = userInfo_["id"] as? Int, 6 < notificationId_ {
                getDetails(isRefresh: false, isSilentCall: false)
                return
            }
            if let id_ = userInfo_[OrderIdKey] as? Int, let statusString = userInfo_["status"] as? String {
                let status_ = OrderStatus.fromStringValue(hashValue: statusString)
                if let orderId = order?.id, orderId == id_ {
                    var order_ = order
                    order_?.status = status_
                    if let link_ = userInfo_["link"] as? String {
                        if self.order?.status != .completed && self.order?.status != .cancelled && self.order?.status != .failed {
                            if status_ == .confirm, order_?.pickupTrackingLink == nil {
                                order_?.pickupTrackingLink = link_
                            } else if status_ == .onTheWay, order_?.deliveryTracingLink == nil {
                                order_?.deliveryTracingLink = link_
                            }
                            self.loadWebView()
                            self.bottomView.isHidden = false
                            self.bottomViewHeightConstraint.constant = self.bottomViewHeight
                        } else {
                            self.hideBottomView()
                            self.orderTableView.tableHeaderView = nil
                            self.orderTableView.tableFooterView = nil
                        }
                    }
                    order = order_
                    self.orderTableView.reloadData()
                }
            }
        } else {
            getDetails(isRefresh: true, isSilentCall: true)
        }
    }
    
    func reloadDetailsData(isRefresh: Bool) {
        self.rowCount = (self.order?.orderType == .special) ? 5 : 6
        self.filterItemsOfOutlet()
        if self.order?.status != .completed && self.order?.status != .cancelled && self.order?.status != .failed {
            if true == self.order?.isFleetOutLet {
                self.hideBottomView()
                self.orderTableView.tableHeaderView = nil
                self.orderTableView.tableFooterView = nil
            } else {
                self.loadWebView()
                self.bottomView.isHidden = false
                self.bottomViewHeightConstraint.constant = self.bottomViewHeight
            }
        } else {
            self.hideBottomView()
            self.orderTableView.tableHeaderView = nil
            self.orderTableView.tableFooterView = nil
        }
        
        if 0 < orderChargeArray.count {
            orderChargeArray.removeAll()
        }
        
        if let charge_ = order?.charge, charge_ > 0 {
            orderChargeArray.append((type: "subtotal", value: charge_, handleFeeType: ""))
        }
        if let deliveryCharge_ = order?.deliveryCharge {
            orderChargeArray.append((type: "deliveryCharge", value: deliveryCharge_, handleFeeType: ""))
        }
        if let discountAmount_ = order?.discountAmount, discountAmount_ > 0 {
            orderChargeArray.append((type: "discountAmount", value: discountAmount_, handleFeeType: ""))
        }
        if let tipAmount_ = order?.tipAmount, tipAmount_ > 0 {
            orderChargeArray.append((type: "tipAmount", value: tipAmount_, handleFeeType: ""))
        }

//        var handlingFee: Double = order?.handlingFeePercent ?? 0
//        let handlingFeeType: String = order?.handleFeeType ?? ""
//        let discount = order?.discountAmount ?? 0
        if shouldDisplayHandlingFee() {
//            var handleFeeType: String = "AMOUNT"
//            let subTotal = order?.charge ?? 0
//            if subTotal > 0 {
//                if handlingFeeType == "PERCENTAGE" {
//                    handlingFee = (subTotal - discount) * handlingFee / 100
//                }
//            } else if handlingFeeType == "PERCENTAGE" {
//                handleFeeType = "PERCENTAGE"
//            }
//
            var costStruct = CostStruct()
            costStruct.orderCost = order?.charge ?? 0
            let handlingFee = costStruct.handlingFee(outlet: order?.outlet)
            if handlingFee > 0 {
                orderChargeArray.append((type: "handleFee", value: handlingFee, handleFeeType: "AMOUNT"))
            } else {
                orderChargeArray.append((type: "handleFee", value: (Double) (costStruct.percentValueOfHandlingFee(outlet: order?.outlet)), handleFeeType: "PERCENTAGE"))
            }
        }

        var grandTotal = (order?.charge ?? 0)
        grandTotal += (order?.deliveryCharge ?? 0)
        grandTotal += (order?.tipAmount ?? 0)
        grandTotal += order?.handleFee ?? 0
        grandTotal -= (order?.discountAmount ?? 0)
        grandTotal = max(0, grandTotal)
        orderChargeArray.append((type: "grandTotal", value: grandTotal, handleFeeType: ""))
//        if let grandTotal_ = order?.grandTotal {
//            orderChargeArray.append((type: "grandTotal", value: grandTotal_ + handleFee))
//        }

        self.orderTableView.reloadData()
        startAnimationTimer()
    }

//    func shouldDisplayHandlingFee() -> Bool {
//        if let handleFeeType = order?.handleFeeType, handleFeeType == "PERCENTAGE", let handlingPercent = order?.handlingFeePercent,  handlingPercent > 0 {
//            return true
//        }
//        if (order?.charge ?? 0) > 0 || order?.handleFeeType == "PERCENTAGE" {
//            return (order?.handleFee ?? 0) > 0
//        }
//        return false
//    }
    
    func shouldDisplayHandlingFee() -> Bool {
        if (order?.outlet?.handleFee ?? 0) > 0 {
            return true
        } else if !(order?.outlet?.isPartnerOutLet ?? false) {
            return (Utilities.shared.appSettings?.handleFee ?? 0) > 0
        }
        return false
    }
    
// MARK: - Support Methods
    
    private func loadWebView() {
        let navigationBarHeight = (true == Utilities.shared.isIphoneX()) ? 108.0 : NavigationBarHeight
        orderTableView.tableHeaderView?.frame.size.height = ScreenHeight - navigationBarHeight - 125.0 //125.0 is minimum height of OrderHistoryPendingCell
        if self.order?.status == .pending {
//            tapgesture.isEnabled = false
            dimView.isHidden = false
            trackLabel.isHidden = false
        } else {
//            tapgesture.isEnabled = true
            dimView.isHidden = true
            trackLabel.isHidden = true
        }
        
        if self.order?.status == .onTheWay {
            if let urlString_ = self.order?.deliveryTracingLink, urlString_.count > 0 {
                loadRequest(url: urlString_)
            }
        } else {
            if let urlString_ = self.order?.pickupTrackingLink, urlString_.count > 0 {
                loadRequest(url: urlString_)
            }
        }
        startAnimationTimer()
    }
    
    fileprivate func startAnimationTimer() {
        Utilities.shared.cancelTimer()
        if let order_ = order, let status_ = order_.status {
            var hashValue = OrderStatus.hashValueFrom(status: status_)
            if true == order_.isFleetOutLet {
                hashValue = OrderStatus.hashValueForFleetType(status: status_)
                guard hashValue != -1 else { return }
                if order?.status == .pending {
                    Utilities.shared.startTimer()
                }
                return
            }
            
            if 0 ... 2 ~= hashValue {
                Utilities.shared.startTimer()
            }
        }
    }
    
    private func loadRequest(url: String) {
        
        let request = URLRequest(url: URL(string: url) ?? URL(fileURLWithPath: ""))
        webView.loadRequest(request)
        activityIndicator.startAnimating()
    }
    
    private func filterItemsOfOutlet() {
        
        if order?.orderType == .special {
            specialOrderItems = order?.items
            return
        }
        
        if let order_ = order, let items_ = order_.items {
            orderItems = items_
        }
        
        if let outlet_ = order?.outlet, let outletItems_ = outlet_.outletItems, let orderItems_ = orderItems {
            let orderIds = orderItems_.map { $0.itemId }.compactMap { $0 }
            _ = outletItems_.filter({ (item) -> Bool in
                _ = orderItems_.map({ (orderItem) -> OrderItem in
                    if orderItem.itemId == item.id ?? 0 {
                        modifyCartQuantityOfOutletItem(item, orderItem: orderItem)
                    }
                    return orderItem
                })
                if orderIds.contains(item.id ?? 0) {
                    return true
                }
                return false
            })
        }
    }
    
    private func modifyCartQuantityOfOutletItem(_ item: OutletItem, orderItem: OrderItem) {
        
        if let quantity_ = orderItem.quantity {
            item.cartQuantity = quantity_
            NSLog("cartQuantity:%ld", item.cartQuantity)
        }

        if let price_ = orderItem.price {
            item.price = price_
        }
        
        if let customItems_ = orderItem.customItems {
            
            _ = customItems_.map ({ (customItem) -> OrderCustomItem in
                
                if let customisationItems_ = item.customisationItems {
                    
                    modifyCustomItems(customisationItems_, customOrderItem: customItem)
                }
                return customItem
            })
        }
    }
    
    private func modifyCustomItems(_ customisationItems_: [CustomizeCategory], customOrderItem: OrderCustomItem) {
        
        _ = customisationItems_.map ({ (category) -> CustomizeCategory in
            
            if let items_ = category.items {
                
                _ = items_.map({ (customizeItem) -> CustomizeItem in
                    
                    if customizeItem.id == customOrderItem.itemId {
                        
                        if let quantity_ = customOrderItem.quantity {
                            
                            if category.categoryMode == .count {
                                customizeItem.quantity = quantity_
                            } else {
                                customizeItem.quantity = 1
                                if category.categoryMode == .check {
                                    
                                } else {
                                    
                                }
                                customizeItem.isCheck = true
                            }
                        }
                        if let price_ = customOrderItem.price {
                            customizeItem.price = price_
                        }
                    }
                    return customizeItem
                })
            }
            return category
        })
    }
    
    override func editAction(_ sender: UIButton?) {
        super.editAction(sender)
        self.navigateBack(nil)
//        self.navigationController?.popViewController(animated: true)
    }

    private func dismiss() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let navController = appDelegate.window?.rootViewController as? UINavigationController else {
            return
        }
        guard let tabController = navController.viewControllers.first as? TabBarController else {
            return
        }

        Utilities.shouldHideTabCenterView(tabController, false)
        if let order_ = order, let type_ = order_.orderType, type_ == .special {
            if true == isVendorOutLet {
                if let homeNavController = tabController.viewControllers?.first as? UINavigationController {
                    let homeController = homeNavController.viewControllers[0]
                    homeNavController.setViewControllers([homeController], animated: true)
                    
                    if let searchNavController = tabController.viewControllers?[1] as? UINavigationController {
                        let searchController = searchNavController.viewControllers[0]
                        searchNavController.setViewControllers([searchController], animated: true)
                    }
                }
            } else {
                if let orderNavController = tabController.viewControllers?[2] as? UINavigationController {
                    if let orderController = orderNavController.viewControllers[0] as? OrderAnythingController {
                        orderController.clearOrder()
                    }
                }
            }
        } else {
            if let homeNavController = tabController.viewControllers?.first as? UINavigationController {
                let homeController = homeNavController.viewControllers[0]
                homeNavController.setViewControllers([homeController], animated: true)
                
                if let searchNavController = tabController.viewControllers?[1] as? UINavigationController {
                    let searchController = searchNavController.viewControllers[0]
                    searchNavController.setViewControllers([searchController], animated: true)
                }
            }
        }
        if let historyNavController = tabController.viewControllers?[3] as? UINavigationController {
            let historyController = historyNavController.viewControllers[0]
            historyNavController.setViewControllers([historyController], animated: true)
        }
        
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
// MARK: - IBActions
    
    @IBAction func tableViewPanGesture(_ sender: Any) {
        
    }
    
//    @IBAction func showTracking(_ sender: UITapGestureRecognizer) {
//
//        let storyboard = Utilities.getStoryBoard(forName: .orderHistory)
//        if let trackingController = storyboard.instantiateViewController(withIdentifier: "OrderTrackingController") as? OrderTrackingController {
//            trackingController.order = self.order
//            self.navigationController?.pushViewController(trackingController, animated: true)
//        }
//    }
    
    @IBAction func onTapArrow(_ sender: UIButton) {
        let orderChargesSectionIndex = 4
        switch self.arrowButtonState {
        case .up:
            orderTableView.scrollToRow(at: IndexPath(row: 0, section: 0 ), at: .bottom, animated: true)
        case .down:
            orderTableView.scrollToRow(at: IndexPath(row: orderChargeArray.count - 1, section: orderChargesSectionIndex), at: .bottom, animated: true)
        case .none:
            break
        }
    }
}

extension OrderDetailsController: UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate, OrderHistoryDelegate, OrderDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard (orderItems != nil) || (specialOrderItems != nil) else {
            return 0.0
        }
        return (section == 3) ? 41.0 : 0.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 3 {
            let aView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: ScreenWidth, height: 41.0))
            aView.backgroundColor = .white
            let aLabel = UILabel(frame: CGRect(x: 20.0, y: 10.0, width: ScreenWidth - 40.0, height: 21.0))
            aLabel.text = NSLocalizedString("Your order details:", comment: "")
            aLabel.font = UIFont.montserratRegularWithSize(18.0)
            aLabel.textAlignment = .left
            aLabel.textColor = .selectedTextColor()
            aView.addSubview(aLabel)
            return aView
        }
        return UIView()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard (orderItems != nil) || (specialOrderItems != nil) else {
            return 0
        }
        
        if 0 == section {
            if self.order?.status != .completed && self.order?.status != .cancelled && self.order?.status != .failed {
                return 2
            }
            return 1
        } else if 2 == section {
            let diffTime = Int(floor(order?.scheduledDate?.timeIntervalSince1970 ?? 0))
            if 0 < diffTime {
               return 2
            }
            return 1
        } else if 3 == section {
            if order?.orderType == .special {
                if let specialOrderItems_ = specialOrderItems {
                    return specialOrderItems_.count
                }
            } else {
                if let orderItems_ = orderItems {
                    return orderItems_.count
                }
            }
        } else if 4 == section {
            return orderChargeArray.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let count = (order?.orderType == .special) ? (specialOrderItems?.count ?? 0) : (orderItems?.count ?? 0)
        switch indexPath.section {
        case 0://Order pending
            if 1 == indexPath.row {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderPendingCell.cellIdentifier(), for: indexPath) as? OrderPendingCell else {
                    return UITableViewCell()
                }
                cell.delegate = self
                if let order_ = order {
                    cell.loadOrderDetails(order_, shouldHideSeperator: true, isFromDetailsScreen: true, shouldShowOrderStageView: false)
                }
                return cell
            }
            
            if self.order?.status == .completed || self.order?.status == .cancelled || self.order?.status == .failed {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderPendingCell.cellIdentifier(), for: indexPath) as? OrderPendingCell else {
                    return UITableViewCell()
                }
                cell.delegate = self
                if let order_ = order {
                    cell.loadOrderDetails(order_, shouldHideSeperator: true, isFromDetailsScreen: true)
                }
                return cell
            }
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderHistoryPendingCell.cellIdentifier()) as? OrderHistoryPendingCell else {
                return UITableViewCell()
            }
            cell.delegate = self
            if let order_ = order {
                cell.loadOrderDetails(order_, shouldHideSeperator: true, isFromDetailsScreen: true)
            }
            return cell
        case 1://Address
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderAddressCell.cellIdentifier(), for: indexPath) as? OrderAddressCell else {
                return UITableViewCell()
            }
            if let shippingAddress = order?.shippingAddress {
                cell.loadAddress(shippingAddress)
            }
            return cell
        case 2://Payment or schedule pickup
            let diffTime = Int(floor(order?.scheduledDate?.timeIntervalSince1970 ?? 0))
            if 0 < diffTime, indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodInfoCell.cellIdentifier(), for: indexPath) as? PaymentMethodInfoCell else {
                    return UITableViewCell()
                }
                let scheduledTime_ = Utilities.getSystemDateString(date: order?.scheduledDate, "E, MMM dd, yyyy, hh:mm a")
                cell.updateSceduledInformation(scheduledTime: scheduledTime_)
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodInfoCell.cellIdentifier(), for: indexPath) as? PaymentMethodInfoCell else {
                    return UITableViewCell()
                }
                let paymentType = order?.paymentType ?? ""
                cell.updatePaymentMethodInformation(paymentType: paymentType)
                return cell
            }
        case 3://Order items
            if indexPath.row <= count {
                if order?.orderType == .special {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: SpecialOrderItemCell.cellIdentifier(), for: indexPath) as? SpecialOrderItemCell else {
                        return UITableViewCell()
                    }
                    if let specialOrderItem = specialOrderItems?[indexPath.row] {
                        cell.loadItem(specialOrderItem)
                    }
                    return cell
                }
                
                guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderItemCell.cellIdentifier(), for: indexPath) as? OrderItemCell else {
                    return UITableViewCell()
                }
                if let orderItem = orderItems?[indexPath.row] {
                    cell.loadItem(orderItem)
                }
                return cell
            } else {
                return UITableViewCell()
            }
        case 4://Order charges
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderChargeCell.cellIdentifier(), for: indexPath) as? OrderChargeCell else {
                return UITableViewCell()
            }
            
            if count > 0, indexPath.row < orderChargeArray.count {
                let orderCharge = orderChargeArray[indexPath.row]
                switch orderCharge.type {
                case "subtotal":
                    cell.chargeType = .subTotal
                    cell.loadPrice(price: orderCharge.value)
                case "deliveryCharge":
                    cell.chargeType = .delivery
                    if let deliveryCharge_ = order?.deliveryCharge {
                        if let order_ = order {
                            cell.loadPrice(price: deliveryCharge_, order: order_)
                        } else {
                            cell.loadPrice(price: deliveryCharge_)
                        }
                        //                    cell.loadPrice(price: deliveryCharge_)
                    } else {
                        if let order_ = order {
                            cell.loadPrice(price: 0.0, order: order_)
                        } else {
                            cell.loadPrice(price: 0.0)
                        }
                    }
                case "discountAmount":
                    cell.chargeType = .discount
                    cell.loadPrice(price: orderCharge.value)
                case "tipAmount":
                    cell.chargeType = .tip
                    cell.loadPrice(price: orderCharge.value, order: order)
                case "grandTotal":
                    cell.chargeType = .grandTotal
                    cell.loadPrice(price: orderCharge.value)
                case "handleFee":
                    cell.chargeType = .handlingFee
                    cell.loadPrice(price: orderCharge.value, handleFeeType: orderCharge.handleFeeType)
                default:
                    return cell
                }
            }
            return cell
        default:
            return UITableViewCell()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let isFleetOutLet = order?.isFleetOutLet, !isFleetOutLet else { return }
        guard order?.status != .completed && order?.status != .cancelled && order?.status != .failed else {
            return
        }
        updateBottomViewForChangesIn(scrollView)
    }

    private func updateBottomViewForChangesIn(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let viewHeight = scrollView.bounds.size.height
        let scrollOffset = scrollView.contentOffset.y
        if scrollOffset <= 0 {
            // show bottom view with down arrow
            arrowButtonState = .down
        } else if (scrollOffset + viewHeight) >= contentHeight {
            // show bottom view with up arrow
            arrowButtonState = .up
        } else {
            // hide bottomView
            arrowButtonState = .none
        }
    }

    private func showBottomView(withUpArrow: Bool) {
        // unhide bottomView and set it's height to maximum
        bottomViewHeightConstraint.constant = bottomViewHeight
        bottomView.isHidden = false

        // set background color
        bottomView.backgroundColor = withUpArrow ? .clear : .black

        // set image for button
        let imageName = withUpArrow ? "doubleUpArrow" : "doubleDownArrow"
        arrowButton.setImage(UIImage(named: imageName), for: .normal)
    }

    private func hideBottomView() {
        // hide bottomView and set it's height to minimum
        bottomView.isHidden = true
        bottomViewHeightConstraint.constant = 0.0
    }
    
// MARK: - UIWebViewDelegate
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.perform(#selector(removeTookanHeader(_:)), with: webView, afterDelay: 2.0)
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        activityIndicator.stopAnimating()
    }
    
    @objc func removeTookanHeader(_ webView: UIWebView) {
        // Removing the tookan header
        webView.stringByEvaluatingJavaScript(from: "document.getElementsByClassName(\"nav1\")[0].style.display=\"none\";")
        DispatchQueue.main.async { [weak self] in
            guard self?.activityIndicator != nil else { return }
            self?.activityIndicator.stopAnimating()
        }
    }
    
// MARK: - OrderHistoryDelegate

//    func repeatOrder(order_: Order) {
//
//        //Internal method
//        func shouldNavigateToOrderAnythingScreen() {
//            let mainSB = Utilities.getStoryBoard(forName: .main)
//            let controller = mainSB.instantiateViewController(withIdentifier: "OrderAnythingController") as! OrderAnythingController
//            if let aOutlet = order_.outlet {
//                controller.outlet = aOutlet
//            }
//            controller.removeMultiLocationPopUp()
//            controller.shouldRepeatOrder = true
//            controller.isFromOrderDetailsScreen = true
//            controller.hidesBottomBarWhenPushed = true
//            controller.isVendorOutLet = true
//            controller.specialOrder = self.formSpecialOrder(order_)
//            Utilities.shouldHideTabCenterView(self.tabBarController, true)
//            self.navigationController?.pushViewController(controller, animated: true)
//        }
//
//        guard Utilities.shared.isNetworkReachable() else {
//            showNoInternetMessage()
//            return
//        }
//
//        if let aOutlet = order_.outlet, let outletId = aOutlet.id {
//            self.loadOutletDetails(outletId: outletId, completionHandler: { (isOutletDetailsFetched, outlet_) in
//                if true == isOutletDetailsFetched {
//                    if let updatedOutlet = outlet_, let updatedOutletId = updatedOutlet.id {
//                        debugPrint(updatedOutletId)
//                        if false == updatedOutlet.showVendorMenu { //isPartnerOutLet
//                            shouldNavigateToOrderAnythingScreen()
//                        } else {
//                            if order_.orderType == .normal {
//                                let checkOutSB = Utilities.getStoryBoard(forName: .checkOut)
//                                let cartController = checkOutSB.instantiateViewController(withIdentifier: "CartViewController") as! CartViewController
//                                cartController.order = order_
//                                cartController.shouldRepeatOrder = true
//                                self.navigationController?.pushViewController(cartController, animated: true)
//                            }
//                            else {
//                                DispatchQueue.main.async(execute: {
//                                    let storyBoard = Utilities.getStoryBoard(forName: .main)
//                                    let controller = storyBoard.instantiateViewController(withIdentifier: "OutletDetailsViewController") as! OutletDetailsViewController
//                                    controller.shouldRepeatOrder = true
//                                    controller.isFromOrderDetailsScreen = true
//                                    controller.outlet = aOutlet
//                                    controller.loadRestaurantDetails { (isRestaurantDetailsFetched) in
//                                        if (true == isRestaurantDetailsFetched) {
//                                            controller.loadRestaurantDetails(isRepeatOrder: true, completionHandler: { (isOutDetailsFetched) in
//                                                if true == isOutDetailsFetched {
//                                                    controller.isFromSearchScreen = false
//                                                    self.navigationController?.pushViewController(controller, animated: true)
//
//                                                    let message = CartMessage.allItemRemoved.description()
//                                                    let popupVC = PopupViewController()
//                                                    let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "\(message)", buttonText: nil, cancelButtonText: "Ok")
//
//                                                    responder.addCancelAction({
//                                                    })
//                                                }
//                                            })
//                                        }
//                                    }
//                                })
//                            }
//                        }
//                    }
//                }
//            })
//        }
//    }

    func formSpecialOrder(_ order: Order) -> SpecialOrder {
        
        var items_ = [[String: AnyObject]]()
        if let items = order.items {
            items_ = items.map ({ (item) -> [String: AnyObject]? in
                if let name_ = item.name {
                    return [NameKey: name_ as AnyObject, QuantityKey: 1 as AnyObject, ProductImageKey: [String]() as AnyObject]
                }
                return nil
            }).compactMap { $0 }
        }
        var address_: Address?
        do {
            var addressDict = [String: AnyObject]()
            if let pickUpLocation_ = order.pickUpLocation, let lat_ = order.latitude, let long_ = order.longitude {
                addressDict[LocationKey] = pickUpLocation_ as AnyObject
                addressDict[LatitudeKey] = lat_ as AnyObject
                addressDict[LongitudeKey] = long_ as AnyObject
                let address: Address = try unbox(dictionary: addressDict)
                address_ = address
            }
        } catch {
            
        }
        return SpecialOrder(items: items_, productImagesArray: [], location: address_, instructions: order.instructions ?? "")
    }
    
// MARK: - OrderDelegate
    
    // below is the redundancy code(from OrderHistoryController) need to change
    
    func orderDelegate(order_: Order) {
        
        if order_.status == .pending {
            cancelOrder(order_)
        } else if false == order_.isOrderProcessing() {
            repeatOrder(order_: order_)
        } else {
            showSupportPopUp()
        }
    }
        
    func showSupportPopUp() {
        
    }
    
    func cancelOrder(_ order: Order) {
        let storyboard = Utilities.getStoryBoard(forName: .orderHistory)
        if let orderCancelViewController = storyboard.instantiateViewController(withIdentifier: "OrderCancelViewController") as? OrderCancelViewController {
            orderCancelViewController.order = order
            self.navigationController?.pushViewController(orderCancelViewController, animated: true)
        }
        
        // Uncomment the above below code for reject messages to cancel the order and remove the below code
//        let popupVC = PopupViewController()
//        let responder = popupVC.showAlert(viewcontroller: self, title: "Are you sure?", text: "Do you really want to delete this order?", buttonText: "Cancel", cancelButtonText: "YES")
//        responder.addCancelAction({
//            DispatchQueue.main.async(execute: {
//                guard Utilities.shared.isNetworkReachable() else {
//                    self.showNoInternetMessage()
//                    return
//                }
//
//                Utilities.showHUD(to: self.view, "")
//
//                if let disposeObj_ = self.disposeObj {
//                    disposeObj_.dispose()
//                }
//
//                let requestObj: [String: AnyObject] = ["orderId": order.id as AnyObject,
//                                                       "reason": "Test for cancellation" as AnyObject,
//                                                       "comment": "Test for cancellation" as AnyObject]
//
//                self.disposeObj =  ApiManager.shared.apiService.cancelOrder(requestObj).subscribe(onNext: { [weak self](order_) in
//                    Utilities.hideHUD(from: self?.view)
//                    self?.navigationController?.popViewController(animated: true)
//                    }, onError: { [weak self](error) in
//                        Utilities.hideHUD(from: self?.view)
//                        if let error_ = error as? ResponseError {
//                            if error_.getStatusCodeFromError() == .accessTokenExpire {
//
//                            } else {
//                                Utilities.showToastWithMessage(error_.description())
//                            }
//                        }
//                })
//                self.disposeObj?.addDisposableTo(self.disposableBag)
//            })
//        })
    }
    
    func repeatOrder(order_: Order) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        if order_.orderType == .special {
            
            let checkoutController = ConfirmOrderController.instantiateFromStoryBoard(.checkOut)
            checkoutController.specialOrder = Utilities.formSpecialOrder(order_)
            checkoutController.shouldRepeatOrder = true
            checkoutController.orderType = .special
            checkoutController.vehicleType = order_.vehicleType
            if let aOutlet = order_.outlet {
                checkoutController.outlet = aOutlet
            }

            let cartNavController = UINavigationController(rootViewController: checkoutController)
            cartNavController.isNavigationBarHidden = true
            navigationController?.present(cartNavController, animated: true, completion: nil)
            
        } else {
            // set UUID string as cart ID
            Utilities.shared.cartId = UUID().uuidString

            let cartController = CartViewController.instantiateFromStoryBoard(.checkOut)
            cartController.order = order_
            cartController.shouldRepeatOrder = true
            
            let cartNavController = UINavigationController(rootViewController: cartController)
            cartNavController.isNavigationBarHidden = true
            navigationController?.present(cartNavController, animated: true, completion: nil)
        }
    }

}

protocol OrderDetailsDelegate: class {
    func changedOrderInfo()
}
