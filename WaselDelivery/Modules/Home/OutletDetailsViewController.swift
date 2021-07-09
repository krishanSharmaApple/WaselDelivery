//
//  OutletDetailsViewController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 16/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import RxSwift
import SDWebImage
import XLPagerTabStrip

class OutletDetailsViewController: BaseViewController, MultiLocationPopUpProtocol {
    
    @IBOutlet weak var timingLabel: UILabel!
    @IBOutlet weak var pagerView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var menuTableView: UITableView!
    @IBOutlet weak var menuTableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var multiLocationButton: UIButton!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var timeLabelBgViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuTableTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var restaurantImageView: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var handleFeeLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!

    var disposbleBag = DisposeBag()
    var sessionTask: URLSessionTask?
    var selectedOutletInformation: OutletsInfo?
    var shouldRepeatOrder = false
    var isFromOrderDetailsScreen: Bool = false
    private var isViewDidLoad = false

    var isFromSearchScreen: Bool = false {
        didSet {
            if let outletsArray = self.selectedOutletInformation?.outlet, 1 < outletsArray.count {
                if nil != multiLocationButton {
                    multiLocationButton.isHidden = false
                }
                if true == isFromSearchScreen {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(100), execute: {
                        self.showMultilocationPopUp(self.multiLocationButton)
                    })
                }
            } else {
                if nil != multiLocationButton {
                    multiLocationButton.isHidden = true
                }
            }
        }
    }

    var outlet: Outlet!
    var itemsArray: [OutletItemCategory]?
    var titlesCount: Int?
    let appSettingsLabelTag = 2525
    fileprivate var multiLocationPopUpViewController: MultiLocationPopUpViewController?
    fileprivate var outletStatusMessage = ""
    var productId = ""
    var isFromDeeplink: Bool = false

// MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        if let outletsArray = self.selectedOutletInformation?.outlet, outletsArray.count > 1 {
            multiLocationButton.isHidden = false
        } else {
            multiLocationButton.isHidden = true
        }
        multiLocationPopUpViewController = MultiLocationPopUpViewController(nibName: "MultiLocationPopUpViewController", bundle: .main)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateOrderDetailsTableHeight(_:)),
                                               name: NSNotification.Name(rawValue: OrderDetailsTableViewHeightNotification),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enableScrolling(_:)),
                                               name: NSNotification.Name(rawValue: EnableRestaurantTableViewScrollNotification),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrderDetailsTableHeight(_:)), name: UIApplication.didChangeStatusBarFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAppOpenCloseStateUI), name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)

        menuTableView.register(UINib(nibName: "HeaderView", bundle: nil),
                                  forHeaderFooterViewReuseIdentifier: "HeaderView")
        
        addNavigationView()
        navigationView?.backgroundColor = .white
        navigationView?.alpha = 0.0
//        loadRestaurantDetails()
        self.updateUI()
        createInfoView(.emptySearch)
        self.infoView?.isHidden = true
        loadRestaurantHeader()
        
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: slectedPaymentMethod)
        userDefaults.synchronize()
        isViewDidLoad = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if true == Utilities.shared.isIphoneX() {
            headerViewHeightConstraint.constant = 204.0
            backButtonTopConstraint.constant = 44.0
            timeLabelBgViewTopConstraint.constant = 53.0
            menuTableTopConstraint.constant = 108.0
        } else {
            headerViewHeightConstraint.constant = 180.0
            backButtonTopConstraint.constant = 20.0
            timeLabelBgViewTopConstraint.constant = 29.0
            menuTableTopConstraint.constant = 84.0
        }
        Utilities.removeTransparentView()
        Utilities.shouldHideTabCenterView(tabBarController, true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Utilities.showTransparentView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.OUTLET_DETAILS_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.OUTLET_DETAILS_TAG)

        if shouldRepeatOrder && Utilities.shared.cart.cartItems.count > 0 {
            let cartItems_ = self.itemsArray?.filter { $0.name != "Recommended"}.compactMap { $0.categories }.flatMap { $0 }.compactMap { $0.foodItems }.flatMap { $0 }.map ({ (item_) -> OutletItem in
                _ = Utilities.shared.cart.cartItems.map({ (cartItem) -> OutletItem in
                    if item_.id == cartItem.id {
                        item_.cartQuantity = cartItem.cartQuantity
                    }
                    return cartItem
                })
                return item_
            })
            if let items_ = cartItems_?.filter({ $0.cartQuantity > 0 }) {
                Utilities.shared.cart.cartItems = items_
            }
            Utilities.shared.reloadCartView()
            self.updateOrderDetailsTableHeight(nil)
        }
        Utilities.shared.reloadCartView()
        
        if true == isFromDeeplink {
            isFromDeeplink = false
            if false == productId.isEmpty {
//                NotificationCenter.default.post(name: NSNotification.Name(rawValue: DeepLinkProductNotification), object: productId)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func navigateBack(_ sender: Any?) {
        
        if Utilities.shared.cart.cartItems.count > 0 {
            let popupVC = PopupViewController()
            let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "Your order will be lost because you can only order from one shop at a time.", buttonText: "Cancel", cancelButtonText: "Clear")
            responder.addCancelAction({
                DispatchQueue.main.async(execute: {
                    // send event to UPSHOT before clearing cart
                    let params = ["CartID": Utilities.shared.cartId ?? ""]
                    UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CLEAR_CART_EVENT, params: params)

                    Utilities.shared.clearCart()
                    Utilities.shared.currentOutlet = nil
//                    Utilities.shouldHideTabCenterView(self.tabBarController, false)
//                    self.navigationController?.popToRootViewController(animated: true)
                    UPSHOTActivitySetup.shared.closeEvent(eventId: BKConstants.VIEW_STORE_ORDER_EVENT)
                    if true == self.isFromOrderDetailsScreen {
                        if let aViewController = self.navigationController?.viewControllers[1], aViewController is OrderDetailsController {
                            Utilities.shouldHideTabCenterView(self.tabBarController, true)
                            self.navigationController?.popToViewController(aViewController, animated: true)
                        } else {
                            Utilities.shouldHideTabCenterView(self.tabBarController, false)
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    } else {
                        Utilities.shouldHideTabCenterView(self.tabBarController, false)
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                })
            })
        } else {
            if let sessionTask_ = sessionTask {
                sessionTask_.cancel()
            }
            Utilities.shared.currentOutlet = nil
            Utilities.shouldHideTabCenterView(tabBarController, false)
            UPSHOTActivitySetup.shared.closeEvent(eventId: BKConstants.VIEW_STORE_ORDER_EVENT)

            if true == self.isFromOrderDetailsScreen {
                if let aViewController = self.navigationController?.viewControllers[1], aViewController is OrderDetailsController {
                    Utilities.shouldHideTabCenterView(self.tabBarController, true)
                    self.navigationController?.popToViewController(aViewController, animated: true)
                } else {
                    Utilities.shouldHideTabCenterView(self.tabBarController, false)
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else {
                Utilities.shouldHideTabCenterView(self.tabBarController, false)
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    deinit {
        Utilities.shared.isOpen = true
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: EnableRestaurantTableViewScrollNotification),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: OrderDetailsTableViewHeightNotification),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
    }
    
    @objc private func updateAppOpenCloseStateUI() {
        Utilities.removeTransparentView()
//        self.updatePagerViewFrame()
        UIView.performWithoutAnimation({
            self.menuTableView.reloadData()
        })
    }

    @objc func enableScrolling(_ notification: Notification) {
        
        self.menuTableView.isScrollEnabled = Utilities.shared.isOpen

        UIView.animate(withDuration: 0.5, animations: {
            self.menuTableView.contentOffset = CGPoint.zero
            self.navigationView?.alpha = 0.0
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    @objc func updateOrderDetailsTableHeight(_ notification: Notification?) {
        if nil != Utilities.shared.cartView {
            let statusBarFrame: CGRect = UIApplication.shared.statusBarFrame
            var bottomPosition = (60.0 + (20.0 >= statusBarFrame.size.height ? 0.0 : (statusBarFrame.size.height - 20.0)))
            if true == Utilities.shared.isIphoneX() {
                bottomPosition = (55.0 + (44.0 >= statusBarFrame.size.height ? 0.0 : (statusBarFrame.size.height - 44.0)))
            }
            menuTableViewBottomConstraint.constant = bottomPosition
            self.tabBarController?.tabBar.isHidden = false
        } else {
            menuTableViewBottomConstraint.constant = 0.0
            self.tabBarController?.tabBar.isHidden = true
        }
        self.view.layoutIfNeeded()
    }
    
    func updatePagerViewFrame() {
        let height = ScreenHeight - NavigationBarHeight // 21 for appSettings height
        pagerView.frame = CGRect(x: 0.0, y: 0.0, width: ScreenWidth, height: height)
    }
    
// MARK: - IBActions Methods
    
    @IBAction func showHandlingFeeInfo(_ sender: UIButton) {
        let controller = HandlingFeeInfoViewController.instantiateFromStoryBoard(.main)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .overCurrentContext

        DispatchQueue.main.async {
            self.present(controller, animated: true, completion: nil)
        }
    }

    @IBAction func waselPartner(_ sender: UIButton) {
        let popupVC = PopupViewController()
        let outletName = Utilities.fetchOutletName(outlet)
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "\(outletName) is a WASEL PARTNER", buttonText: nil, cancelButtonText: "Ok")
        responder.setCancelButtonColor(.white)
        responder.setCancelTitleColor(.unSelectedTextColor())
        responder.setCancelButtonBorderColor(.unSelectedTextColor())
    }
    
    @IBAction func goBack(_ sender: AnyObject) {
        navigateBack(nil)
    }
    
    @IBAction func showMultilocationPopUp(_ sender: Any) {
        if let outletsArray = self.selectedOutletInformation?.outlet, 1 < outletsArray.count {
            multiLocationPopUpViewController?.delegate = self
            if let selectedOutletIndex = self.selectedOutletInformation?.selectedOutletIndex, -1 == selectedOutletIndex, true == isFromSearchScreen {
                self.selectedOutletInformation?.selectedOutletIndex = 0
            }
            multiLocationPopUpViewController?.selectedOutletInformation = self.selectedOutletInformation
            multiLocationPopUpViewController?.modalPresentationStyle = .overCurrentContext
            if let multiLocationPopUpController = self.multiLocationPopUpViewController {
                self.tabBarController?.present(multiLocationPopUpController, animated: true, completion: {
                    self.multiLocationPopUpViewController?.loadData()
                })
            }
        }
    }
    
    // MARK: - MultiLocation popup methods
    
    func removeMultiLocationPopUp() {
        // Remove MultiLocation Popup
        multiLocationPopUpViewController?.dismiss(animated: true, completion: nil)
        multiLocationPopUpViewController?.delegate = nil
    }

    func pushToDetailsScreen(selectedOutlet: Outlet, outletsInfo_: OutletsInfo) {
        // send event to UPSHOT before clearing cart
        let params = ["CartID": Utilities.shared.cartId ?? ""]
        UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CLEAR_CART_EVENT, params: params)

        Utilities.shared.clearCart()
        self.updateOrderDetailsTableHeight(nil)
        
        if let aOutletId = selectedOutlet.id {
            self.loadOutletDetails(outletId: aOutletId, completionHandler: { (isOutletDetailsFetched, outlet_) in
                if true == isOutletDetailsFetched {
                    if false == outlet_?.showVendorMenu { //isPartnerOutLet
                        let controller = OrderAnythingController.instantiateFromStoryBoard(.main)
                        controller.outlet = selectedOutlet
                        if controller.specialOrder.didEditedOrder() {
                            let popupVC = PopupViewController()
                            let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "When you leave this place cart will be cleared. Do you want to clear?", buttonText: "Cancel", cancelButtonText: "Clear")
                            responder.addCancelAction({
                                DispatchQueue.main.async(execute: {
                                    controller.clearOrder()
                                    controller.isVendorOutLet = true
                                    controller.selectedOutletInformation = outletsInfo_
                                    self.removeMultiLocationPopUp()
                                    self.navigationController?.pushViewController(controller, animated: true)
                                })
                            })
                        } else {
                            controller.isVendorOutLet = true
                            controller.selectedOutletInformation = outletsInfo_
                            self.removeMultiLocationPopUp()
                            self.navigationController?.pushViewController(controller, animated: true)
                        }
                    } else {
                        self.removeMultiLocationPopUp()
                        self.outlet = selectedOutlet
                        self.loadRestaurantDetails()
                        self.updateUI()
                        self.createInfoView(.emptySearch)
                        self.infoView?.isHidden = true
                        self.loadRestaurantHeader()
                        self.outletStatusMessage = Utilities.isOutletOpen(self.outlet).message
                        self.loadTimings()
                        Utilities.shouldHideTabCenterView(self.tabBarController, true)
                    }
                }
            })
        }
    }
    
// MARK: - API Methods
    
    func loadRestaurantDetails(isRepeatOrder: Bool? = false, getHeaderDetails: Bool = false, storeId: String? = "", completionHandler: ((_ isRestaurantDetailsFetched: Bool, _ outlet: Outlet?) -> Void)? = nil) {

        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        var path = URI.outletItems.rawValue
        if nil != outlet {
            if let outletId = outlet.id, 0 < outletId {
                path = URI.outletItems.rawValue + "\(outletId)"
            } else {
                if let storeId_ = storeId, false == storeId_.isEmpty {
                    if let storeId = Int(storeId_) {
                        path = URI.outletItems.rawValue + "\(storeId)"
                    }
                }
            }
        } else if let storeId_ = storeId, false == storeId_.isEmpty {
            if let storeId = Int(storeId_) {
                path = URI.outletItems.rawValue + "\(storeId)"
            }
        }
//        var path = URI.outletItems.rawValue + "\(outlet.id ?? 0)"
        if (true == isRepeatOrder) || getHeaderDetails {
            guard let userLocation = Utilities.getUserLocation() else {
                Utilities.showToastWithMessage("Please select location.")
                return
            }
            let latitude = userLocation.latitude as AnyObject
            let longitude = userLocation.longitude as AnyObject
            let secondsFromGMT = NSTimeZone.local.secondsFromGMT() as AnyObject
            if getHeaderDetails {
                path = URI.outletItems.rawValue + (storeId ?? "0") + "/\(latitude)" + "/\(longitude)" + "/\(secondsFromGMT)"
            } else {
                path = URI.outletItems.rawValue + "\(outlet.id ?? 0)" + "/\(latitude)" + "/\(longitude)" + "/\(secondsFromGMT)"
            }
        }

        let request = ApiManager.clientURLRequest(path, method: .get)
        let session = URLSession(configuration: URLSessionConfiguration.default)

        // Display indicator
        Utilities.showHUD(to: nil, nil)

        if ApiManager.shared.apiServiceType == .apiService {
            sessionTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
                DispatchQueue.main.async {

                    // Hide indicator
                    Utilities.hideHUD(from: nil)

                    if self.isViewDidLoad {
                        Utilities.hideHUD(from: self.view)
                    }

                    let response = response as? HTTPURLResponse

                    if let response_ = response {
                        if response_.statusCode == ResponseStatusCode.success.rawValue {
                            if let data_ = data {
                                do {
                                    let json = try JSONSerialization.jsonObject(with: data_, options: .mutableContainers) as AnyObject
                                    Utilities.log(json as AnyObject, type: .info)
                                    if let json_ = json as? [String: AnyObject] {
                                        if (true == isRepeatOrder) || getHeaderDetails {
                                            let outletsInfo: OutletsInfo = try unbox(dictionary: json_)
                                            if let outlet_: Outlet = outletsInfo.outlet?.first {
                                                self.updateOutletHeaderDetails(outlet_: outlet_, shouldUpdateUI: self.isViewDidLoad)
                                            }
                                        } else {
                                            self.parseOutlet(json_: json_, shouldUpdateUI: self.isViewDidLoad)
                                            if true == storeId?.isEmpty || self.isViewDidLoad {
                                                self.updateUI()
                                            }
                                        }
                                        if let acompletionHandler = completionHandler {
                                            acompletionHandler(true, self.outlet)
                                        }
                                    } else {
                                        if let acompletionHandler = completionHandler {
                                            Utilities.showToastWithMessage(ResponseError.parseError.description())
                                            acompletionHandler(false, self.outlet)
                                        }
                                    }
                                } catch {
                                    if let acompletionHandler = completionHandler {
                                        Utilities.showToastWithMessage(ResponseError.parseError.description())
                                        acompletionHandler(false, self.outlet)
                                    }
//                                    self.goBackWithMessage(message: ResponseError.parseError.description())
                                }
                            } else if let error_ = error {
                                if let acompletionHandler = completionHandler {
                                    Utilities.showToastWithMessage(error_.localizedDescription)
                                    acompletionHandler(false, self.outlet)
                                }
//                                self.goBackWithMessage(message: error_.localizedDescription)
                            }
                        } else if response_.statusCode == ResponseStatusCode.accessTokenExpire.rawValue {
                        
                        } else {
                            if let data_ = data {
                                do {
                                    let json = try JSONSerialization.jsonObject(with: data_, options: .mutableContainers) as? [String: Any]
                                    if let message = json?["message"] as? String {
                                        if let acompletionHandler = completionHandler {
                                            Utilities.showToastWithMessage(message)
                                            acompletionHandler(false, self.outlet)
                                        }
//                                        self.goBackWithMessage(message: message)
                                    }
                                } catch {
                                    if let acompletionHandler = completionHandler {
                                        Utilities.showToastWithMessage(ResponseError.unkonownError.description())
                                        acompletionHandler(false, self.outlet)
                                    }
//                                    self.goBackWithMessage(message: (ResponseError.unkonownError.description()))
                                }
                            } else if let error_ = error {
                                if let acompletionHandler = completionHandler {
                                    Utilities.showToastWithMessage(error_.localizedDescription)
                                    acompletionHandler(false, self.outlet)
                                }
//                                self.goBackWithMessage(message: error_.localizedDescription)
                            } else {
                                if let acompletionHandler = completionHandler {
                                    Utilities.showToastWithMessage(ResponseError.unkonownError.description())
                                    acompletionHandler(false, self.outlet)
                                }
//                                self.goBackWithMessage(message: ResponseError.unkonownError.description())
                            }
                        }
                    } else {
                        if let data_ = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data_, options: .mutableContainers) as? [String: AnyObject]
                                if let message = json?["message"] as? String {
                                    if let acompletionHandler = completionHandler {
                                        Utilities.showToastWithMessage(message)
                                        acompletionHandler(false, self.outlet)
                                    }
//                                    self.goBackWithMessage(message: message)
                                }
                            } catch {
                                // observer.on(.error(ResponseError.unkonownError))
                            }
                        } else if let error_ = error {
                            if let acompletionHandler = completionHandler {
                                Utilities.showToastWithMessage(error_.localizedDescription)
                                acompletionHandler(false, self.outlet)
                            }
//                            self.goBackWithMessage(message: error_.localizedDescription)
                        } else {
                            if let acompletionHandler = completionHandler {
                                Utilities.showToastWithMessage(ResponseError.unkonownError.description())
                                acompletionHandler(false, self.outlet)
                            }
//                            self.goBackWithMessage(message: ResponseError.unkonownError.description())
                        }
                    }
                }
            }
            sessionTask?.resume()
        } else if ApiManager.shared.apiServiceType == .staticService {
            let outletItems = ApiManager.shared.apiService.getOutletItems(["id": "\(outlet.id ?? 0)"])
            _ = outletItems.subscribe(onNext: { (items) in
                
                self.filterItems(items)
                if let acompletionHandler = completionHandler {
                    acompletionHandler(true, self.outlet)
                }
            }, onError: { (error) in
                if nil != self.outlet {
                    Utilities.hideHUD(from: self.view)
                }
                // handle error
                if let error_ = error as? ResponseError {
                    if error_.getStatusCodeFromError() == .accessTokenExpire {
                        
                    } else {
                        Utilities.showToastWithMessage(error_.description())
                    }
                }
                if let acompletionHandler = completionHandler {
                    acompletionHandler(false, self.outlet)
                }
            }).disposed(by: disposbleBag)
        }
    }
    
    private func parseOutlet(json_: [String: AnyObject], shouldUpdateUI: Bool = true) {
        
        do {
            if nil == self.outlet {
                let outlet_: Outlet = try unbox(dictionary: json_)
                self.outlet = outlet_
            }
            let distance = self.outlet.distance
            let deliveryCharge = self.outlet.deliveryCharge
            let timing = self.outlet.timing
            let openTiming = self.outlet.opentime
            let firstShiftStartTime = self.outlet.firstShiftStartTime
            let firstShiftEndTime = self.outlet.firstShiftEndTime
            let secondShiftStartTime = self.outlet.secondShiftStartTime
            let secondShiftEndTime = self.outlet.secondShiftEndTime
            
            let outlet_: Outlet = try unbox(dictionary: json_)
            self.outlet = outlet_
            self.outlet.distance = distance
            self.outlet.deliveryCharge = deliveryCharge
            self.outlet.timing = timing
            self.outlet.opentime = openTiming
            self.outlet.firstShiftStartTime = firstShiftStartTime
            self.outlet.firstShiftEndTime = firstShiftEndTime
            self.outlet.secondShiftStartTime = secondShiftStartTime
            self.outlet.secondShiftEndTime = secondShiftEndTime
            self.outlet.outletTimings = outlet_.outletTimings

            let isPartnerFlag = (self.outlet.isPartnerOutLet ?? false) ? "Yes" : "No"
            let ownDeliveryStatus = (self.outlet.isFleetOutLet ?? false) ? "Yes" : "No"
            let params: [String: Any] = [
                "StoreName": self.outlet.name ?? "",
                "StoreID": String(self.outlet.id ?? 0),
                "CategoryName": self.outlet.amenity?.name ?? "",
                "CategoryID": self.outlet.amenity?.id ?? "",
                "DeliveryCharge": self.outlet.deliveryCharge ?? 0.0,
                "Partner": isPartnerFlag,
                "Distance": self.outlet.distance ?? 0.0,
                "OwnDelivery": ownDeliveryStatus,
                "CartID": Utilities.shared.cartId ?? ""
            ]
            UPSHOTActivitySetup.shared.createCustomTimedEvent(eventName: BKConstants.VIEW_STORE_ORDER_EVENT, params: params)
            UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.VIEW_STORE_TAG)
            if self.isViewDidLoad {
                updateUI()
            }
        } catch {
            self.goBackWithMessage(message: ResponseError.unboxParseError.description())
        }
    }
    
    func updateOutletHeaderDetails(outlet_: Outlet, shouldUpdateUI: Bool = true) {
        if outlet == nil {
            self.outlet = outlet_
        } else {
            outlet.distance = outlet_.distance
            outlet.deliveryCharge = outlet_.deliveryCharge
            outlet.timing = outlet_.timing
            outlet.opentime = outlet_.opentime
            outlet.firstShiftStartTime = outlet_.firstShiftStartTime
            outlet.firstShiftEndTime = outlet_.firstShiftEndTime
            outlet.secondShiftStartTime = outlet_.secondShiftStartTime
            outlet.secondShiftEndTime = outlet_.secondShiftEndTime
        }
        guard shouldUpdateUI else { return }
        self.updateUI()
    }
    
    func updateUI() {
        if let outletItems_ = self.outlet.outletItems, outletItems_.count > 0 {
            self.filterItems(outletItems_)
            self.loadRestaurantHeader()
        } else {
            self.itemsArray = [OutletItemCategory]()
            if let aArray = self.itemsArray, aArray.count > 0 {
                self.infoView?.isHidden = true
            } else {
                if infoView == nil {
                    showInfoMessageWitType(.emptySearch)
                }
                self.infoView?.isHidden = false
            }
            if menuTableView != nil {
                menuTableView.reloadData()
            }
            return
        }
        Utilities.shared.currentOutlet = self.outlet
    }
    
    private func goBackWithMessage(message: String) {
        Utilities.shouldHideTabCenterView(self.tabBarController, false)
        DispatchQueue.main.async(execute: {
            Utilities.showToastWithMessage(message)
            _ = self.navigationController?.popViewController(animated: true)
        })
    }
    
    func filterItems(_ items: [OutletItem]) {
        
        var itemCategories = [OutletItemCategory]()
        let categoryTitles = items.compactMap { $0.itemCategory?.parent?.name }.reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
        let recommended = items.filter { $0.isRecommended == true && $0.itemCategory?.disable == false }
        for title in categoryTitles {
            let categoryItems = items.filter { $0.itemCategory?.parent?.name == "\(title)" }
            let subCategorieTitles = categoryItems.compactMap { $0.itemCategory?.name }.reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
            var subCategoryItems = [OutletItemSubCategory]()
            for subTitle in subCategorieTitles {
                let subItems = categoryItems.filter { $0.itemCategory?.name == "\(subTitle)" }
                let outletSubCategory = OutletItemSubCategory(name_: "\(subTitle)", items_: subItems)
                subCategoryItems.append(outletSubCategory)
            }
            itemCategories.append(OutletItemCategory(name_: "\(title)", categories_: subCategoryItems))
        }
        let singleCategoryArray = itemCategories.filter { $0.categories?.count == 1 }
        for __sub in singleCategoryArray {
            if let firstSub = __sub.categories?[0] {
                firstSub.isExpanded = true
            }
        }
        if recommended.count > 0 {
            itemCategories.insert(OutletItemCategory(name_: "Recommended", categories_: [OutletItemSubCategory(name_: "", items_: recommended, isExpand: true)]), at: 0)
        }
        updateOutletDetails(itemCategories)
    }

    /// Get details of the product
    ///
    /// - Parameters:
    ///   - id: id of a product
    ///   - itemCategories: array of outlet item categories
    /// - Returns: index of the OutletItemController and OutletItem object based on productId given
    private func getProductDetailsBy(id: String, from itemCategories: [OutletItemCategory]) -> (viewControllerIndex: Int, outletItem: OutletItem?) {
        func contains(category: OutletItemCategory, productId: String) -> Bool {
            return category.categories?.contains(where: { subCat -> Bool in
                return subCat.foodItems?.contains(where: { "\($0.id ?? -1)" == productId }) ?? false
            }) ?? false
        }

        var viewControllerIndex: Int = -1
        var outletItem: OutletItem?

        if !productId.isEmpty {
            for (index, category) in itemCategories.enumerated() where contains(category: category, productId: productId) {
                catLoop: for subCat in category.categories ?? [] {
                    for item in subCat.foodItems ?? [] where "\(item.id ?? -1)" == productId {
                        outletItem = item
                        break catLoop
                    }
                }
                viewControllerIndex = index
                break
            }
        }

        return (viewControllerIndex, outletItem)
    }
    
    func updateOutletDetails(_ itemCategories: [OutletItemCategory]) {
        let (viewControllerIndex, outletItem) = getProductDetailsBy(id: productId, from: itemCategories)
        
        DispatchQueue.main.async(execute: {
            Utilities.hideHUD(from: self.view)
            self.itemsArray = itemCategories
            if let aArray = self.itemsArray, aArray.count > 0 {
                self.infoView?.isHidden = true
                if let child = self.children.last, child is OrderDetailsPagerController {
                    if let childController = child as? OrderDetailsPagerController {
                        childController.outletCategories = aArray
                        if viewControllerIndex >= 0 {
                            childController.outletItem = outletItem
                            childController.defaultControllerIndex = viewControllerIndex
                        }
                    }
                }
                self.menuTableView.reloadData()
            } else {
                self.infoView?.isHidden = false
            }
        })
    }
    
    func getMenuTitles() -> [String] {
        var titles = [String]()
        if let restaurantDetailsArray_ = itemsArray {
            titles = restaurantDetailsArray_.compactMap { $0.name ?? "" }
        }
        return titles
    }
    
    func loadRestaurantHeader() {
        guard restaurantImageView != nil else { return }
        
        // restaurant image
        if let imageUrl_ = outlet.imageUrl, imageUrl_.count > 0 {
            restaurantImageView.sd_setImage(with: URL(string: imageUrl_), placeholderImage: UIImage(named: "outlet_placeholder"))
        } else {
            restaurantImageView.image = UIImage(named: "outlet_placeholder")
        }
        
        // name
        if nil != outlet.name {
            let outletName = Utilities.fetchOutletName(outlet)
            restaurantNameLabel.text = outletName.trim()
            navigationView?.titleLabel.text = outletName.trim()
        }
        distanceLabel.attributedText = Utilities.getDistanceAttString(outlet: outlet)
        if true == outlet.isFleetOutLet {
            costLabel.attributedText = NSAttributedString(string: outlet.ownFleetDescription ?? "")
        } else {
            costLabel.attributedText = Utilities.getDeliveryChargeAttString(outlet: outlet)
        }

        var pricesString = ""
        let handlingFeeString = Utilities.getHandleFeeStringFrom(outlet: outlet)
        if outlet.showVendorMenu ?? false {
            let minOrderString = Utilities.getMinimumOrderStringFrom(outlet: outlet)
            pricesString += minOrderString.isEmpty ? "" : minOrderString
        }

        infoButton.isHidden = true
        if !handlingFeeString.isEmpty {
            pricesString += pricesString.isEmpty ? "" : " | "
            pricesString += handlingFeeString
            infoButton.isHidden = false
        }
        handleFeeLabel.text = pricesString

        guard outlet != nil else { return }
        outletStatusMessage = Utilities.isOutletOpen(outlet).message
        loadTimings()
    }
    
    fileprivate func loadTimings() {
//        let outletStatus = Utilities.isOutletOpen(outlet)
        timingLabel.text = outletStatusMessage
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        if Utilities.shared.isOpen == true {
            return .lightContent
        }
        return .default
    }
}

extension OutletDetailsViewController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let itemsArray_ = itemsArray, itemsArray_.count >= 0 {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        Utilities.removeTransparentView()

        let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell", for: indexPath)
        for view in cell.contentView.subviews {
            if appSettingsLabelTag != view.tag {
                view.removeFromSuperview()
            } else {
                if let appSettingsLabel = view.viewWithTag(appSettingsLabelTag) as? UILabel {
                    if Utilities.isWaselDeliveryOpen() {
                        appSettingsLabel.text = ""
                    } else {
                        let userDefaults = UserDefaults.standard
                        if let appOpenCloseStatusMessageString = userDefaults.object(forKey: appOpenCloseStatusMessage) as? String, 0 < appOpenCloseStatusMessageString.count {
                            appSettingsLabel.text = appOpenCloseStatusMessageString
                        } else {
                            appSettingsLabel.text = NSLocalizedString("App closed now", comment: "")
                        }
                    }
                }
            }
        }
        if let itemsArray_ = itemsArray, itemsArray_.count > 0 {
            if false == cell.contentView.subviews.contains(pagerView) {
                cell.contentView.addSubview(pagerView)
            }
            let contentViewFrame = cell.contentView.bounds
            let yPos: CGFloat = (true == Utilities.isWaselDeliveryOpen()) ? 0.0 : 21.0
            pagerView.frame = CGRect(x: contentViewFrame.origin.x, y: yPos, width: contentViewFrame.size.width, height: contentViewFrame.size.height - yPos)
        } else {
            if let infoView_ = infoView {
                cell.contentView.addSubview(infoView_)
                infoView_.infoDescriptionLabel.text = "We're updating the menu. Please visit us soon."
                infoView_.center = cell.contentView.center
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let itemsArray_ = itemsArray {
            let statusBarFrame: CGRect = UIApplication.shared.statusBarFrame
            let bottomPosition = (20.0 >= statusBarFrame.size.height ? 0.0 : (statusBarFrame.size.height - 20.0))

            if itemsArray_.count == 0 {
                return ScreenHeight - NavigationBarHeight - 96.0 - bottomPosition
            }
            
            if nil != Utilities.shared.cartView {
                return ScreenHeight - NavigationBarHeight - bottomPosition - 60.0
            }
            return ScreenHeight - NavigationBarHeight - bottomPosition
        }
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.y
        if offset > 0 {
            if offset < ScrollOffset {
                let percentage = offset / ScrollOffset
                navigationView?.alpha = percentage
                UIView.animate(withDuration: 0.5, animations: {
                    self.menuTableView.contentOffset = CGPoint(x: 0.0, y: ScrollOffset)
                })
            } else {
                navigationView?.alpha = 1.0
                Utilities.shared.isOpen = false
                UIView.animate(withDuration: 0.25, animations: {
                    self.setNeedsStatusBarAppearanceUpdate()
                })
                self.menuTableView.isScrollEnabled = Utilities.shared.isOpen
                NotificationCenter.default.post(name: Notification.Name(rawValue: EnableItemTableViewScrollNotification), object: nil, userInfo: nil)
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset = scrollView.contentOffset.y
        if offset == 0 {
            navigationView?.alpha = 0.0
        } else if offset == ScrollOffset {
            navigationView?.alpha = 1.0
        }
    }
}
