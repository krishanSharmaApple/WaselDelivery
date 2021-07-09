//
//  CartViewController.swift
//  WaselDelivery
//
//  Created by sunanda on 11/14/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import SDWebImage
import Upshot

class CartViewController: BaseViewController {

    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var cartTableView: UITableView!
    @IBOutlet weak var totalCostLabel: UILabel!
    @IBOutlet weak var totalItemsLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var outletTitleLabel: UILabel!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkOutButton: UIButton!
    @IBOutlet weak var topViewConstraint: NSLayoutConstraint!
//    @IBOutlet weak var checkOutButtonBottomConstraint: NSLayoutConstraint!

    var shouldRepeatOrder = false
    var order: Order?
    fileprivate var disposeObj: Disposable?
    fileprivate var disposableBag = DisposeBag()

    var showNotification: Any!
    var hideNotification: Any!
    var cartOutletItems = [OutletItem]()
    var instructionsTextView: UITextView?

    var isTextView = false
    var currentTextFieldTag = 0
    var orderDetailsDelegate: OrderDetailsDelegate?
    var currentVehicle: VehicleType = .motorbike
    var deliveryCharge: DeliveryCharge?

// MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reformCartItems()
        setNavigationView()
        loadViewData()
        if shouldRepeatOrder == true {
            if order != nil {
                repeatOrder()
            }
        }
        cartTableView.estimatedRowHeight = 131.0
        cartTableView.rowHeight = UITableView.automaticDimension
        cartTableView.register(FoodItemCell.nib(), forCellReuseIdentifier: FoodItemCell.cellIdentifier())
        NotificationCenter.default.addObserver(self, selector: #selector(updateAppOpenCloseStateUI), name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
        
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkOutButton.backgroundColor = UIColor(red: (85.0/255.0), green: (190.0/255.0), blue: (109.0/255.0), alpha: isAppOpen ? 1.0
            : 0.5)
        checkOutButton.isEnabled = isAppOpen
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if true == Utilities.shared.isIphoneX() {
//            checkOutButtonBottomConstraint.constant = -20.0
            topViewConstraint.constant = 20.0
        } else {
//            checkOutButtonBottomConstraint.constant = 0.0
            topViewConstraint.constant = 0.0
        }
//        registerForKeyBoardNotification()
        NotificationCenter.default.addObserver(self, selector: #selector(checkout(_:)), name: NSNotification.Name(rawValue: ProceedToCheckOutNotification), object: nil)
        if Utilities.shared.cart.cartItems.count > 0 {
            reformCartItems()
            cartTableView.reloadData()
        }
        getDeliveryChargesWithVehicles()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.CART_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.CART_SCREEN_TAG)
        if Utilities.shared.cart.cartItems.count > 0 {
            cartTableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        if let disposeObj_ = disposeObj {
            disposeObj_.dispose()
        }
//        NotificationCenter.default.removeObserver(showNotification)
//        NotificationCenter.default.removeObserver(hideNotification)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ProceedToCheckOutNotification), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
    }
    
    func getDeliveryChargesWithVehicles() {
        if Utilities.getUser() != nil {
            Utilities.showHUD(to: self.view, "")
            var requestObj: [String: Any] = [:]
            guard let outlet_ = Utilities.shared.currentOutlet, let address = outlet_.address else {
                cartTableView.reloadData()
                return
            }
            let userLocation = Utilities.getUserLocation()
            requestObj["latitude"] = userLocation?.latitude ?? 0.0
            requestObj["longitude"] = userLocation?.longitude ?? 0.0
            requestObj["outletLatitude"] = address.latitude ?? 0.0
            requestObj["outletLongitude"] = address.longitude ?? 0.0
            requestObj["orderType"] = OrderType.normal.rawValue
            
            ApiManager.shared.apiService.deliveryChargesByVehicleType(requestObj as [String: AnyObject]).subscribe(
                onNext: { [weak self](deliveryChargeObj) in
                    Utilities.hideHUD(from: self?.view)
                    self?.deliveryCharge = deliveryChargeObj
                    self?.cartTableView.reloadData()
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
    
    // MARK: - Notification Refresh methods
    
    @objc private func updateAppOpenCloseStateUI() {
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkOutButton.backgroundColor = UIColor(red: (85.0/255.0), green: (190.0/255.0), blue: (109.0/255.0), alpha: isAppOpen ? 1.0
            : 0.5)
        checkOutButton.isEnabled = isAppOpen
        UIView.performWithoutAnimation {
            self.cartTableView.reloadData()
        }
    }

    override func navigateBack(_ sender: Any?) {
        
        if shouldRepeatOrder && Utilities.shared.cart.cartItems.count > 0 {
            
            let popupVC = PopupViewController()
            let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "Your order will be lost because you can only order from one shop at a time.", buttonText: "Cancel", cancelButtonText: "Clear")
            
            responder.addCancelAction({
                DispatchQueue.main.async(execute: {
                    // send event to UPSHOT before clearing cart
                    let params = ["CartID": Utilities.shared.cartId ?? ""]
                    UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CLEAR_CART_EVENT, params: params)

                    Utilities.shared.clearCart()
                    self.navigationController?.dismiss(animated: true, completion: nil)
                })
            })
        } else {
            navigationController?.dismiss(animated: true, completion: nil)
        }
        orderDetailsDelegate?.changedOrderInfo()

        // Remove above code and uncomment the below code for Repeate order
        /*
        if shouldRepeatOrder { //&& Utilities.shared.cart.cartItems.count > 0
            DispatchQueue.main.async(execute: {
                let storyBoard = Utilities.getStoryBoard(forName: .main)
                let controller = storyBoard.instantiateViewController(withIdentifier: "OutletDetailsViewController") as! OutletDetailsViewController
                controller.shouldRepeatOrder = true
                controller.outlet = Utilities.shared.currentOutlet
                controller.loadRestaurantDetails { (isRestaurantDetailsFetched) in
                    if (true == isRestaurantDetailsFetched) {
                        if true == self.shouldRepeatOrder {
                            controller.loadRestaurantDetails(isRepeatOrder: true, completionHandler: { (isOutDetailsFetched) in
                                if true == isOutDetailsFetched {
                                    controller.isFromSearchScreen = false
                                    self.navigationController?.pushViewController(controller, animated: true)
                                }
                            })
                        }
                        else {
                            controller.isFromSearchScreen = false
                            self.navigationController?.pushViewController(controller, animated: true)
                        }
                    }
                }
            })
        } else {
            navigationController?.dismiss(animated: true, completion: nil)
        }
         */
    }
    
// MARK: - IBActions
    
    @IBAction func checkout(_ sender: Any) {
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkOutButton.isEnabled = isAppOpen
        if false == isAppOpen {
            return
        }
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        guard Utilities.isUserLoggedIn() else {
            
            let loginVC = LoginViewController.instantiateFromStoryBoard(.login)
            loginVC.isFromCheckout = true
            let navController = UINavigationController(rootViewController: loginVC)
            navController.isNavigationBarHidden = true
            self.navigationController?.present(navController, animated: true, completion: nil)
            return
        }
        
        let userInfo = BKUserInfo.init()
        let infoDict = ["CartItemsCount": Utilities.shared.cart.cartItems.count]
        userInfo.others = infoDict
        userInfo.build(completionBlock: nil)

        let totalCost = Utilities.shared.getTotalCost()
        if let currentOutlet = Utilities.shared.currentOutlet, currentOutlet.showVendorMenu ?? false, totalCost < (currentOutlet.minimumOrderValue ?? 0) {
            Utilities.showToastWithMessage("Minimum order value should be \(currentOutlet.minimumOrderValue ?? 0) BD")
            return
        }
        
        if Utilities.shared.cart.cartItems.count > 0 {
            let country = Utilities.shared.currentOutlet?.address?.country ?? ""
            let address = Utilities.shared.currentOutlet?.address?.getAddressString() ?? ""
            let city = Utilities.shared.currentOutlet?.address?.city ?? ""
            let state = Utilities.shared.currentOutlet?.address?.state ?? ""
            let area = Utilities.shared.currentOutlet?.address?.landmark ?? ""

            let confirmLocationParams: [String: Any] = [
                "City": city,
                "State": state,
                "Country": country,
                "Area": area,
                "Address": address,
                "OrderType": "Store",
                "CartID": Utilities.shared.cartId ?? ""
            ]
            UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CONFIRM_LOCATION_EVENT, params: confirmLocationParams)

            let showVendorMenu_ = Utilities.shared.currentOutlet?.showVendorMenu ?? false
            var params: [String: Any] = [
                "ItemsCount": Utilities.shared.cart.cartItems.count,
                "Type": (false == showVendorMenu_) ? "Vendor" : "Partner",
                "ConfirmLocation": "No",
                "CartID": Utilities.shared.cartId ?? ""
            ]
            if nil != self.instructionsTextView, Utilities.shared.cart.instructions.length > 0 {
                params["Instructions"] = "Yes"
            } else {
                params["Instructions"] = "No"
            }
            UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CHECKOUT_EVENT, params: params)

            let checkoutController = ConfirmOrderController.instantiateFromStoryBoard(.checkOut)
            checkoutController.shouldRepeatOrder = self.shouldRepeatOrder
            checkoutController.orderType = .normal
            checkoutController.vehicleType = currentVehicle
            self.navigationController?.pushViewController(checkoutController, animated: true)
        }
    }
    
    @IBAction func done(_ sender: Any) {
        view.endEditing(true)
    }

// MARK: - Notificaiton Methods
    
    func registerForKeyBoardNotification() {
        showNotification = registerForKeyboardDidShowNotification(tableBottomConstraint, 0.0, shouldUseTabHeight: true, usingBlock: { _ in
            DispatchQueue.main.async(execute: {
                if self.isTextView {
                    self.cartTableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .middle, animated: false)
                }
//                else {
//                    if self.currentTextFieldTag > 0 {
//                        let index = self.currentTextFieldTag % 10
////                        self.cartTableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: false)
//                    }
//                }
            })
        })
        hideNotification = registerForKeyboardWillHideNotification(tableBottomConstraint, 0.0)
    }
    
// MARK: - Support PrivateMethods
    
    fileprivate func reformCartItems() {
        cartOutletItems.removeAll()
        _ = Utilities.shared.cart.cartItems.map({ (outletItem) -> OutletItem in
            if let id_ = outletItem.id {
                let ids = cartOutletItems.map { $0.id ?? 0 }
                if !ids.contains(id_) {
                    if let parent_ = outletItem.parent {
                        if let parentCartItems = parent_.cartItems {
                            cartOutletItems.append(contentsOf: parentCartItems)
                        }
//                        cartOutletItems.append(parent_)
                    } else {
                        cartOutletItems.append(outletItem)
                    }
                }
            }
            return outletItem
        })
    }

    private func setNavigationView() {
        addNavigationView()
        let title = "Hide" //(shouldRepeatOrder == true) ? "Cancel" : "Hide"
        navigationView?.titleLabel.text = "Cart"
        navigationView?.backButton.setTitle(title, for: .normal)
        navigationView?.backButton.titleLabel?.font = UIFont.montserratSemiBoldWithSize(14.0)
        navigationView?.backButton.setTitleColor(UIColor(red: (60.0/255.0), green: (60.0/255.0), blue: (60.0/255.0), alpha: 1.0), for: .normal)
        navigationView?.backButton.setImage(nil, for: .normal)
    }
    
    private func loadViewData() {
        
        if Utilities.shared.cart.cartItems.count > 0 {
            totalItemsLabel.text = String(format: "%02d", Utilities.shared.getTotalItems())
            let text = String(format: "%.3f", Utilities.shared.getTotalCost())
            totalCostLabel.text = text
            
            if let outlet_ = Utilities.shared.currentOutlet, let imageUrl_ = outlet_.imageUrl {
                backgroundImageView.sd_setImage(with: URL(string: imageUrl_), placeholderImage: UIImage(named: "outlet_placeholder"))
            } else {
                backgroundImageView.image = UIImage(named: "outlet_placeholder")
            }
            if let outlet_ = Utilities.shared.currentOutlet, 0 < outlet_.name?.count ?? 0 {
                let outletName = Utilities.fetchOutletName(outlet_)
                outletTitleLabel.text = "\(outletName)"
            }
            if let outlet_ = Utilities.shared.currentOutlet, let address_ = outlet_.address, let location_ = address_.location {
                locationLabel.text = location_
            } else {
                locationLabel.text = ""
            }
        }
    }
    
// MARK: - Repeat Order API
    
    private func repeatOrder() {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        Utilities.showHUD(to: self.view, "Loading...")
        disposeObj = ApiManager.shared.apiService.getOrderDetails(["id": order?.id as AnyObject ] as [String: AnyObject]).subscribe(
            onNext: { [weak self](order) in
                Utilities.hideHUD(from: self?.view)
                self?.order = order
                self?.checkForRemovedItems()
                if order.items != nil {
                    self?.filterItemsOfOutlet()
                    Utilities.shared.currentOutlet = order.outlet
                } else {
                    Utilities.shared.cart.cartItems = [OutletItem]()
                }
                self?.loadViewData()
                self?.cartTableView.reloadData()
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
    
    private func checkForRemovedItems() {
        
        if let order_ = order {
            if let items_ = order_.items, let removedItems_ = order_.removedItems, let outlet_ = order_.outlet, let outletItems_ = outlet_.outletItems, removedItems_.count > 0 {
                
                var message = ""
                var shouldDismiss = false
                let item_ = removedItems_[0]
                let outletItem_ = outletItems_.filter { $0.id ?? 0 == item_.itemId ?? 0 }.compactMap { $0 }
                // must not unwrap
                if items_.count == removedItems_.count {
                    message = (removedItems_.count == 1) ? (outletItem_.count > 0) ? CartMessage.singleItemCustomizationRemoved(item_.name ?? "").description() : CartMessage.itemRemoved(item_.name ?? "").description() : CartMessage.allItemRemoved.description()
                    // if it exists in outlet then it means that customisation is changed
                    if outletItem_.count > 0 {
                        shouldDismiss = false
                    } else {
                        shouldDismiss = true
                    }
                } else if removedItems_.count == 1 {
                    message = (outletItem_.count > 0) ? CartMessage.singleItemCustomizationRemoved(item_.name ?? "").description() : CartMessage.itemRemoved(item_.name ?? "").description()
                } else {
                    message = CartMessage.fewItemRemoved.description()
                }
                
                let popupVC = PopupViewController()
                let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "\(message)", buttonText: nil, cancelButtonText: "Ok")
                responder.setCancelButtonColor(.white)
                responder.setCancelTitleColor(.unSelectedTextColor())
                responder.setCancelButtonBorderColor(.unSelectedTextColor())
                if shouldDismiss == true {
                    responder.addCancelAction({
                        DispatchQueue.main.async(execute: {
                            self.navigationController?.dismiss(animated: true, completion: nil)
                        })
                    })
                }
            }
        }
    }
    
    private func filterItemsOfOutlet() {
        
        if let order_ = order, let outlet_ = order_.outlet, let outletItems_ = outlet_.outletItems, let orderItems_ = order_.items {
            
            let orderIds = orderItems_.map { $0.itemId }.compactMap { $0 }
            
            let filtered = outletItems_.filter({ (item) -> Bool in
                
                _ = orderItems_.map({ (orderItem) -> OrderItem in
                    
                    if orderItem.itemId == item.id ?? 0 {
                        
                        modifyCartQuantityOfOutlet(item: item, orderItem: orderItem)
                    }
                    return orderItem
                })
                if orderIds.contains(item.id ?? 0) {
                    return true
                }
                return false
            })
            Utilities.shared.cart.cartItems = filtered
            
            if Utilities.shared.cart.cartItems.count > 0 {
                reformCartItems()
                cartTableView.reloadData()
            }
        }
    }
    
    private func modifyCartQuantityOfOutlet(item: OutletItem, orderItem: OrderItem) {
        
        if let quantity_ = orderItem.quantity { 
            item.cartQuantity = quantity_
        }//changed cart quantity
        
        changeToDefaultSettigs(shouldReset: false, forItem: item)
        
        if let customItems_ = orderItem.customItems {
            
            _ = customItems_.map ({ (customItem) -> OrderCustomItem in
                
                if let customisationItems_ = item.customisationItems {
                    
                    modifyCustomItems(customisationItems_, customItem: customItem)
                }
                return customItem
            })
        }
        changeToDefaultSettigs(shouldReset: true, forItem: item)
    }
    
    private func modifyCustomItems(_ customisationItems_: [CustomizeCategory], customItem: OrderCustomItem) {
        _ = customisationItems_.map ({ (category) -> CustomizeCategory in
            if let items_ = category.items {
                
                _ = items_.map({ (customizeItem) -> CustomizeItem in
                    
                    if customizeItem.id == customItem.itemId {
                        
                        if let quantity_ = customItem.quantity {
                            
                            if category.categoryMode == .count {
                                customizeItem.quantity = quantity_
                            } else if category.categoryMode == .anyOne {
                                customizeItem.quantity = 1
                                customizeItem.isRadioSelectionEnabled = true
                            } else {
                                customizeItem.quantity = 1
                                customizeItem.isCheck = true
                            }
                        }
                    }
                    return customizeItem
                })
            }
            return category
        })
    }
    
    private func changeToDefaultSettigs(shouldReset: Bool, forItem item: OutletItem) {
        if let customisationItems_ = item.customisationItems {
            
            _ = customisationItems_.map({ (customizeCategory) -> CustomizeCategory in
                if let cItems_ = customizeCategory.items, customizeCategory.categoryMode == .anyOne, cItems_.count > 0 {
                    if shouldReset == true {
                        let cutomisedIds = cItems_.filter { $0.quantity > 0 }
                        if cutomisedIds.count == 0 {
                            cItems_[0].quantity = 1
                            cItems_[0].isRadioSelectionEnabled = shouldReset
                        }
                    } else {
                        cItems_[0].quantity =  0
                        cItems_[0].isRadioSelectionEnabled = shouldReset//making only first item to zero as we are setting the first item of anyone category as default
                    }
                }
                return customizeCategory
            })
        }//setting
    }
    
}

extension CartViewController: UITableViewDelegate, UITableViewDataSource, InstructionsCellProtocol, FoodItemCellDelegate, CartVehicleTypeCellDelegate, RemoveItemAlertDelegate, CustomizeDelegate, ReloadDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            let count = cartOutletItems.count
            return count
        } else if section == 1 || section == 2 {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard cartOutletItems.count > 0 else {
            return UITableViewCell()
        }

        if indexPath.section == 0 {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FoodItemCell.cellIdentifier(), for: indexPath) as? FoodItemCell else {
                return UITableViewCell()
            }
//            let foodItem =  Utilities.shared.cart.cartItems[indexPath.row]
            let foodItem = cartOutletItems[indexPath.row]
            cell.alertDelegate = self
            cell.delegate = self
            cell.reloadDelegate = self
            cell.customiseDelegate = self
            cell.loadCellWithData(foodItem, withImage: shouldRepeatOrder)
            cell.instructionsTextField.tag = 10 + indexPath.row
            cell.instructionsTextField.text = foodItem.instructions.trim().length > 0 ? foodItem.instructions.trim() : ""
            cell.instructionsTextField.delegate = self
            return cell
        } else if indexPath.section == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CartVehicleTypeCell.cellIdentifier(), for: indexPath) as? CartVehicleTypeCell else {
                 return UITableViewCell()
            }
            cell.vehicleDelegate = self
            if let charge = deliveryCharge?.bikeDeliveryCharge {
              cell.motorBikeView.setText(text: ("BD \(Utilities.format(value: charge))"))
            }
            if let charge = deliveryCharge?.carDeliveryCharge {
              cell.carView.setText(text: ("BD \(Utilities.format(value: charge))"))
            }
            if let charge = deliveryCharge?.truckDeliveryCharge {
              cell.truckView.setText(text: ("BD \(Utilities.format(value: charge))"))
            }
            switch self.currentVehicle {
            case .motorbike:
              cell.selectMotorBike()
            case .car:
              cell.selectCar()
            case .truck:
               cell.selectTruck()
            }

            return cell
        } else if indexPath.section == 2 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: InstructionsCell.cellIdentifier(), for: indexPath) as? InstructionsCell else {
                return UITableViewCell()
            }
            self.instructionsTextView = cell.instructionsTextView
            cell.instructionsTextView.text = Utilities.shared.cart.instructions
            cell.placeHolderLabel.isHidden = Utilities.shared.cart.instructions.count > 0 ? true : false
            cell.instructionsTextView.inputAccessoryView = toolBar
            cell.delegate = self
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 || section == 2 ? 46.0 : 0.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard section == 1 || section == 2 else { return nil }
        
        let aView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: ScreenWidth, height: 46.0))
        aView.backgroundColor = .white
        let aLabel = UILabel(frame: CGRect(x: 20.0, y: 25.0, width: ScreenWidth - 40.0, height: 21.0))
        if section == 1 {
            aLabel.text = "Choose your Vehicle"
        } else if section == 2 {
            aLabel.text = "Order / Delivery Instructions"
        }
        aLabel.font = UIFont.montserratLightWithSize(18.0)
        aLabel.textAlignment = .left
        aLabel.textColor = .selectedTextColor()
        aView.addSubview(aLabel)
        return aView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        guard cartOutletItems.count > 0 else {
            return 0
        }
        
        if indexPath.section == 1 {
             return 120
        } else if indexPath.section == 2 {
           if let instructionsTextView_ = self.instructionsTextView, Utilities.shared.cart.instructions.length > 0 {//not knowing if this is correct way of saving textview instance in main view
               let size_ = instructionsTextView_.sizeThatFits(CGSize(width: ScreenWidth - 49.0, height: CGFloat(MAXFLOAT)))
               return size_.height + 28.0
           }
           return 64.0
        }
        
        let foodItem =  cartOutletItems[indexPath.row]
        var height: CGFloat = 0.0
        if let name_ = foodItem.name, name_.length > 0 {
            let height_ = Utilities.getSizeForText(text: name_.trim(), font: .montserratLightWithSize(14.0), fixedWidth: ScreenWidth - 171.0).height
            height = (height_ >= 21.0) ? height_ - 21.0 : 0.0
        }
        if let des_ = foodItem.itemDescription, des_.length > 0 {
            height += Utilities.getSizeForText(text: des_.trim(), font: .montserratLightWithSize(10.0), fixedWidth: ScreenWidth - 137.0).height
        }
        height += 131.0//original view height apart from label including textview
        
//        if let cartItems_ = foodItem.cartItems, cartItems_.count > 0 {
//            height += Utilities.getItemViewHeightForItem(foodItem)
//        }
        return height
    }
    
    func getCellSize(_ title: String, forzeIndexPath indexpath: IndexPath) -> CGSize {
        
        let font = UIFont.montserratLightWithSize(10.0)
        
        let cellRect = (title as NSString).boundingRect(with: CGSize(width: ScreenWidth - 115.0, height: CGFloat(Float.greatestFiniteMagnitude)), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return cellRect.size
    }

    func textViewDidChangeCharacters(_ textView: UITextView) {
        
        Utilities.shared.cart.instructions = textView.text        
        let size = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: size.width,
                                                   height: CGFloat.greatestFiniteMagnitude))
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            cartTableView.beginUpdates()
            cartTableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            cartTableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .middle, animated: false)
        }
    }
    
    func textViewBeginEditing(_ textView: UITextView) {
        isTextView = true
    }

    func textViewEndEditing(_ textView: UITextView) {
        isTextView = false
    }

    func reloadView() {
        
        totalItemsLabel.text = "\(Utilities.shared.getTotalItems())"
        let text = String(format: "%.3f", Utilities.shared.getTotalCost())
        totalCostLabel.text = text
        cartTableView.reloadData()
    }

    func showCustomiseView(forItem item: OutletItem) {
        
        let storyBoard = Utilities.getStoryBoard(forName: .home)
        guard let customiseController = storyBoard.instantiateViewController(withIdentifier: "CustomizeController") as? CustomizeController else {
            return
        }
        customiseController.delegate = self
        customiseController.outletItem = item
        
        let navC = UINavigationController(rootViewController: customiseController)
        navC.providesPresentationContextTransitionStyle = true
        navC.modalPresentationStyle = .overCurrentContext
        navC.definesPresentationContext = true
        navC.isNavigationBarHidden = true
        
        navigationController?.present(navC, animated: true, completion: nil)
    }
    
    func showImagePopUpView(forItem item: OutletItem) {
        if let imageUrlString = item.imageUrl, false == imageUrlString.isEmpty {
            let photoDetailViewController = PhotoDetailViewController.init(nibName: "PhotoDetailViewController", bundle: nil)
            photoDetailViewController.outletItem = item
            photoDetailViewController.modalTransitionStyle = .crossDissolve
            navigationController?.present(photoDetailViewController, animated: true, completion: nil)
        }
    }
    
// MARK: - ReloadParentDelegate
    
    func reloadData() {
        totalItemsLabel.text = "\(Utilities.shared.getTotalItems())"
        let text = String(format: "%.3f", Utilities.shared.getTotalCost())
        totalCostLabel.text = text
        cartTableView.reloadData()
    }
    
// MARK: - RemoveItemAlertDelegate
    
    func showRemoveItemAlert(_ outletItem: OutletItem) {
        
        let message = Utilities.shared.getTotalItems() == 0 ? "Your cart will be cleared. Would you like to proceed?" : "Would you like to remove this item from cart?"
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: message, buttonText: "Cancel", cancelButtonText: "Remove")
        
        responder.addCancelAction({
            DispatchQueue.main.async(execute: {
                outletItem.cartQuantity = 0
                if let parent_ = outletItem.parent {
                    parent_.cartQuantity -= 1 //decrementing count for parent
                    if nil != parent_.cartItems, outletItem.cartQuantity == 0 {
                        if let index = parent_.cartItems?.index(where: { $0 === outletItem }) {
                            parent_.cartItems?.remove(at: index) //removing from parent cartitems
                        }
                    }
                } else {
                    outletItem.instructions = ""
                }
                Utilities.shared.updateCart(outletItem)
                if Utilities.shared.getTotalItems() == 0 {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                } else {
                    self.reformCartItems()
                    self.cartTableView.reloadData()
                    self.reloadView()
                }
            })
        })
        
        responder.addAction({
            DispatchQueue.main.async(execute: {
                self.cartTableView.reloadData()
                self.reloadView()
            })
        })
    }
    
    func selectVehicleType(_ vehicle: VehicleType) {
        self.currentVehicle = vehicle
        self.cartTableView.reloadData()
    }
    
}

extension CartViewController: UITextFieldDelegate {
    
    // MARK: UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= MaxCharacters
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isTextView = false
        currentTextFieldTag = textField.tag
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        isTextView = false
        currentTextFieldTag = 0
        let index = textField.tag % 10
        if index < cartOutletItems.count {
            let item = cartOutletItems[index]
            item.instructions = textField.text?.trim() ?? ""
        }
    }
    
}

class InstructionsCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var instructionsTextView: UITextView!
    @IBOutlet weak var placeHolderLabel: UILabel!
    weak var delegate: InstructionsCellProtocol?
    
    class func cellIdentifier() -> String {
        return "InstructionsCell"
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.textViewBeginEditing(textView)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textViewEndEditing(textView)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        let textLength = textView.text.count
        placeHolderLabel.isHidden = textLength > 0 ? true : false
        delegate?.textViewDidChangeCharacters(textView)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let currentCharacterCount = textView.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + text.count - range.length
        return newLength <= 240
    }
}

class CartVehicleTypeCell: UITableViewCell {
    
    @IBOutlet weak var motorBikeView: VehicleTypeView!
    @IBOutlet weak var carView: VehicleTypeView!
    @IBOutlet weak var truckView: VehicleTypeView!
    
    weak var vehicleDelegate: CartVehicleTypeCellDelegate?
    
    class func nib() -> UINib {
        return UINib(nibName: "CartVehicleTypeCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "CartVehicleTypeCell"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureMotorBike = UITapGestureRecognizer(target: self, action: #selector(tapSelectMotorBike))
        motorBikeView.addGestureRecognizer(tapGestureMotorBike)
        motorBikeView.setText(text: "")
        motorBikeView.setImage(image: "vehicle_motorcycle")
        
        let tapGestureCar = UITapGestureRecognizer(target: self, action: #selector(tapSelectCar))
        carView.addGestureRecognizer(tapGestureCar)
        carView.setText(text: "")
        carView.setImage(image: "vehicle_car")
        
        let tapGestureTruck = UITapGestureRecognizer(target: self, action: #selector(tapSelectTruck))
        truckView.addGestureRecognizer(tapGestureTruck)
        truckView.setText(text: "")
        truckView.setImage(image: "vehicle_truck")
     }
    
    func selectMotorBike() {
        motorBikeView.selectVehicle(true)
        carView.selectVehicle(false)
        truckView.selectVehicle(false)
    }
    
    @objc func tapSelectMotorBike() {
        vehicleDelegate?.selectVehicleType(.motorbike)
    }
    
    func selectCar() {
        carView.selectVehicle(true)
        motorBikeView.selectVehicle(false)
        truckView.selectVehicle(false)
    }
    
    @objc func tapSelectCar() {
        vehicleDelegate?.selectVehicleType(.car)
    }
    
    func selectTruck() {
        truckView.selectVehicle(true)
        carView.selectVehicle(false)
        motorBikeView.selectVehicle(false)
    }
    
    @objc func tapSelectTruck() {
        vehicleDelegate?.selectVehicleType(.truck)
    }
}

extension CartViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        let outletItem_ = cartOutletItems[collectionView.tag]
//        let outletItem_ = Utilities.shared.cart.cartItems[collectionView.tag]
        if let customizations_ = outletItem_.cartItems {
            return customizations_.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemCell.cellIdentifier(), for: indexPath) as? ItemCell else {
            return UICollectionViewCell()
        }
        let outletItem_ = cartOutletItems[collectionView.tag]
        if let cartItem = outletItem_.cartItems?[indexPath.item] {
            cell.loadItemAtIndex(item: cartItem)
        }
        cell.reloadDelegate = self
        cell.alertDelegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let outletItem_ = cartOutletItems[collectionView.tag]
        if let cartItem = outletItem_.cartItems?[indexPath.item] {
            let size_ = CGSize(width: ScreenWidth - 34.0, height: Utilities.getCustomizationStringHeightFor(item: cartItem))
            return size_
        }
        return CGSize.zero
    }
}

protocol InstructionsCellProtocol: class {
    func textViewDidChangeCharacters(_ textView: UITextView)
    func textViewBeginEditing(_ textView: UITextView)
    func textViewEndEditing(_ textView: UITextView)
}

protocol CartVehicleTypeCellDelegate: class {
    func selectVehicleType(_ vehicle: VehicleType)
}


