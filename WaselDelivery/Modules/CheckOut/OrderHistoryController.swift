//
//  OrderHistoryController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 16/11/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import RxSwift

class OrderHistoryController: BaseViewController, OrderDetailsDelegate {
    
    @IBOutlet weak var historyTableView: UITableView!
    
    fileprivate var orders: [Order]?
    fileprivate var shouldFetchOrders = true
    var refreshControl: UIRefreshControl!
    let EmptyCellIdentifier = "EmptyCellIdentifier"
    let PageLimit: Int = 10
    fileprivate var disposeObj: Disposable?
    var disposableBag = DisposeBag()
    var selectedCellRect: CGRect = .zero

    @IBOutlet weak var tableBottomView: UIView!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!

    var screenShotImageView: UIImageView?
    
// MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateAppOpenCloseStateUI), name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
        addNavigationView()
        navigationView?.backButton.isHidden = true
        navigationView?.titleLabel.text = "Order History"
        
        historyTableView.register(UINib(nibName: "OrderPendingCell", bundle: nil), forCellReuseIdentifier: OrderPendingCell.cellIdentifier())
        historyTableView.register(UINib(nibName: "OrderHistoryCell", bundle: nil), forCellReuseIdentifier: OrderHistoryCell.cellIdentifier())
        historyTableView.register(UINib(nibName: "OrderHistoryPendingCell", bundle: nil), forCellReuseIdentifier: OrderHistoryPendingCell.cellIdentifier())

        NotificationCenter.default.addObserver(self, selector: #selector(refreshOrder(_:)), name: NSNotification.Name(RefreshOrderHistoryNotification), object: nil)

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refreshOrders(_:)), for: .valueChanged)
        
        historyTableView.tableFooterView?.frame.size.height = 0.0
        historyTableView.tableFooterView?.isHidden = true
        historyTableView.estimatedRowHeight = 110.0
        historyTableView.rowHeight = UITableView.automaticDimension
        self.createInfoView(.emptyOrderHistory)
        
        var silentCall = false
        if let o = self.orders, o.count > 0 {
            silentCall = true
        }
        self.shouldFetchOrders = true
        getHistory(true, isSilentCall: silentCall)
        
        self.navigationController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utilities.shouldHideTabCenterView(tabBarController, false)
        navigationHeightConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
        if self.shouldStartTimer() == true {
            Utilities.shared.startTimer()
        }
        Utilities.showTransparentView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Utilities.shared.cancelTimer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.ORDER_HISTORY_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.ORDER_HISTORY_SCREEN_TAG)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(RefreshOrderHistoryNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
    }
    
    // MARK: - Notification Refresh methods

    @objc private func updateAppOpenCloseStateUI() {
        Utilities.showTransparentView()
        UIView.performWithoutAnimation {
            self.historyTableView.reloadData()
        }
    }
    
    func changedOrderInfo() {
        self.shouldFetchOrders = true
        getHistory(true, isSilentCall: false)
    }
// MARK: - IBActions
    
    @IBAction func login(_ sender: Any) {
        let storyBoard = Utilities.getStoryBoard(forName: .login)
        if let loginVC = storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let navController = appDelegate?.window?.rootViewController as? UINavigationController
            loginVC.isFromManageProfile = true
            navController?.pushViewController(loginVC, animated: true)

        }
        
    }
    
// MARK: - API Methods
    
    fileprivate func getHistory(_ latest: Bool, isSilentCall: Bool) {
        
        guard Utilities.shared.isNetworkReachable() else {
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            showNoInternetMessage()
            return
        }

        guard Utilities.isUserLoggedIn() == true else {
            orders = nil
            historyTableView.tableFooterView?.frame.size.height = 119.0
            historyTableView.tableFooterView?.isHidden = false
            createInfoView(.loginFromHistory)
            historyTableView.reloadData()
            return
        }
        
        createInfoView(.emptyOrderHistory)
        historyTableView.tableFooterView?.frame.size.height = 0.0
        historyTableView.tableFooterView?.isHidden = true
        if historyTableView.subviews.contains(refreshControl) == false {
            historyTableView.addSubview(refreshControl)
        }
        
        if isSilentCall == false {
            Utilities.showHUD(to: self.view, "Loading...")
        }
        
        var start = 0
        if let orders_ = orders, latest == false {
            start = orders_.count / PageLimit
        }
        
        let user = Utilities.getUser()
        let userId = user?.id ?? ""
        let requestObj: [String: AnyObject] = ["start": start as AnyObject,
                                               "id": userId as AnyObject,
                                               "limit": PageLimit as AnyObject]
        
        _ = ApiManager.shared.apiService.getOrderHistory(requestObj).subscribe(onNext: { [weak self](ordersList) in
            
            Utilities.hideHUD(from: self?.view)
            if self?.refreshControl.isRefreshing == true {
                self?.refreshControl.endRefreshing()
            }
            self?.parseOrders(ordersList, isFetchingLatest: latest)
            if 0 == start {
                self?.historyTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }, onError: { [weak self](error) in
            
            if self?.refreshControl.isRefreshing == true {
                self?.refreshControl.endRefreshing()
            }
            Utilities.hideHUD(from: self?.view)
            if let error_ = error as? ResponseError {
                if error_.getStatusCodeFromError() == .accessTokenExpire {
                    
                } else {
                    Utilities.showToastWithMessage(error_.description())
                }
            }
        })
    }
    
    func parseOrders(_ ordersList: [Order], isFetchingLatest: Bool) {
        
        if ordersList.count > 0 {
            if nil != self.orders, isFetchingLatest == false {
                self.orders?.append(contentsOf: ordersList)
                if ordersList.count < PageLimit {
                    self.shouldFetchOrders = false
                }
            } else {
                self.orders = ordersList
            }
        } else {
            if let orders_ = self.orders, orders_.count > 0 {
                self.shouldFetchOrders = false
            } else {
                self.orders = ordersList
                self.shouldFetchOrders = true
            }
        }
        if self.shouldStartTimer() == true {
            Utilities.shared.startTimer()
        } else {
            Utilities.shared.cancelTimer()
        }
        self.historyTableView.reloadData()
    }
    
    @objc func refreshOrders(_ sender: Any?) {
        shouldFetchOrders = true
        getHistory(true, isSilentCall: true)
    }
    
    fileprivate func shouldStartTimer () -> Bool {
        var shouldStart = false
        if let orders_ = orders, orders_.count > 0 {
            let filteredArr = orders_.filter { $0.status != .completed && $0.status != .cancelled }
            shouldStart = filteredArr.count > 0 ? true : false
        }
        return shouldStart
    }
    
// MARK: - Push Notification method
    
    @objc func refreshOrder(_ notification: Notification) {
        
        let userInfo = notification.userInfo
        if let userInfo_ = userInfo {
            if let id_ = userInfo_[OrderIdKey] as? Int, let statusString = userInfo_["status"] as? String {
                
                if let notificationId_ = userInfo_["id"] as? Int, 6 < notificationId_ {
                    self.shouldFetchOrders = true
                    getHistory(true, isSilentCall: true)
                    return
                }
                let status_ = OrderStatus.fromStringValue(hashValue: statusString)
                if let orders_ = orders {
                    for (index, order_) in orders_.enumerated() {
                        if let orderId = order_.id, orderId == id_ {
                            var o = order_
                            o.status = status_
                            if let link_ = userInfo_["link"] as? String {
                                if status_ == .confirm, o.pickupTrackingLink == nil {
                                    o.pickupTrackingLink = link_
                                } else if status_ == .onTheWay, o.deliveryTracingLink == nil {
                                    o.deliveryTracingLink = link_
                                }
                            }
                            orders?[index] = o
                            break
                        }
                    }
                }
                historyTableView.reloadData()
            }
        } else {
            self.shouldFetchOrders = true
            getHistory(true, isSilentCall: true)
        }
    }
    
    func getPreviousOrdersAtIndex(indexPath: IndexPath) {
        if let orders_ = orders, orders_.count >= PageLimit, indexPath.row == orders_.count - 1 && shouldFetchOrders == true {
            getHistory(false, isSilentCall: true)
        }
    }
    
}

extension OrderHistoryController: UITableViewDataSource, UITableViewDelegate, OrderHistoryDelegate, OrderDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let orders_ = orders, orders_.count > 0 {
            return orders_.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let orders_ = orders {
            if 0 < orders_.count {
                return UITableView.automaticDimension
            } else {
                return ScreenHeight - NavigationBarHeight - TabBarHeight
            }
        }
        return ScreenHeight - NavigationBarHeight - TabBarHeight - 119.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard Utilities.isUserLoggedIn() == true else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: EmptyCellIdentifier, for: indexPath)
            if let infoView_ = infoView {
                cell.addSubview(infoView_)
                infoView_.center = cell.contentView.center
            }
            return cell
        }
        
        if orders == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmptyCellIdentifier, for: indexPath)
            return cell
        } else if let ordersCount = orders?.count, ordersCount == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: EmptyCellIdentifier, for: indexPath)
            if let infoView_ = infoView {
                cell.addSubview(infoView_)
                infoView_.center = cell.contentView.center
            }
            return cell
        }
        
        guard let order = orders?[indexPath.row] else {
            return UITableViewCell()
        }
        guard let orderStatus = order.status else {
            return UITableViewCell()
        }
        
        if orderStatus == .completed || orderStatus == .cancelled || orderStatus == .failed {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderHistoryCell.cellIdentifier()) as? OrderHistoryCell else {
                return UITableViewCell()
            }
            cell.delegate = self
            cell.loadOrderDetails(order_: order)
            getPreviousOrdersAtIndex(indexPath: indexPath)
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderHistoryPendingCell.cellIdentifier()) as? OrderHistoryPendingCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        cell.loadOrderDetails(order, shouldHideSeperator: false)
        getPreviousOrdersAtIndex(indexPath: indexPath)
        return cell

        /*
        let order = orders![indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: OrderPendingCell.cellIdentifier()) as! OrderPendingCell
        cell.delegate = self
        cell.loadOrderDetails(order, shouldHideSeperator: false)
        getPreviousOrdersAtIndex(indexPath: indexPath)
        return cell
        */
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let orders_ = orders, orders_.count > 0 {
            let storyboard = Utilities.getStoryBoard(forName: .orderHistory)
            if let orderDetailsController = storyboard.instantiateViewController(withIdentifier: "OrderDetailsController") as? OrderDetailsController {
                if let orders_ = orders, orders_.count > indexPath.row {
                    orderDetailsController.orderId = orders_[indexPath.row].id ?? 0
                    orderDetailsController.shouldPopBack = true
                    orderDetailsController.hidesBottomBarWhenPushed = true
                    orderDetailsController.orderDetailsDelegate = self
                    let rectInTableView = tableView.rectForRow(at: indexPath)
                    selectedCellRect = tableView.convert(rectInTableView, to: tableView.superview)
                    self.addScreenShotImageOnWindow()
                    self.navigationController?.pushViewController(orderDetailsController, animated: true)
                }
            }
        }
    }
    
    func addScreenShotImageOnWindow() {
        // Observed black patch while navigating to details screen to over come this, Adding the tabbar screen shot image on window.
        if let tabC_ = tabBarController as? TabBarController {
            var cropRect = tabC_.tabBar.frame
            let centerImageDiff: CGFloat = 20.0
            cropRect.origin.y -= centerImageDiff
            cropRect.size.height += centerImageDiff
            if let screenShotImage_ = Utilities.shared.screenShotOfTabBarView(referenceView: tabC_.view, cropRect: cropRect) {
                UIGraphicsEndImageContext()
                screenShotImageView = UIImageView(frame: (cropRect))
                screenShotImageView?.image = screenShotImage_
                UIApplication.shared.keyWindow?.addSubview(screenShotImageView ?? UIImageView())
            }
        }
    }
    
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
        } else if order_.isOrderProcessing() {
            showSupportPopUp()
        } else {
            repeatOrder(order_: order_)
        }
    }
    
    func showSupportPopUp() {
        Utilities.showToastWithMessage("In Progress")
    }
    
    func cancelOrder(_ order: Order) {
        let storyboard = Utilities.getStoryBoard(forName: .orderHistory)
        if let orderCancelViewController = storyboard.instantiateViewController(withIdentifier: "OrderCancelViewController") as? OrderCancelViewController {
            orderCancelViewController.order = order
            self.navigationController?.pushViewController(orderCancelViewController, animated: true)
        }
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
            checkoutController.orderDetailsDelegate = self
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
            cartController.orderDetailsDelegate = self

            let cartNavController = UINavigationController(rootViewController: cartController)
            cartNavController.isNavigationBarHidden = true
            navigationController?.present(cartNavController, animated: true, completion: nil)
        }
        
    }
}

extension OrderHistoryController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard selectedCellRect != .zero else {
            return nil
        }

        switch operation {
        case .push:
            return CustomAnimator(duration: 0.35, isPresenting: true, originalRect: selectedCellRect)
        default:
            let animator = CustomAnimator(duration: 0.35, isPresenting: false, originalRect: selectedCellRect)
            selectedCellRect = .zero
            return animator
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if animated {
            screenShotImageView?.removeFromSuperview()
        }
    }
}
