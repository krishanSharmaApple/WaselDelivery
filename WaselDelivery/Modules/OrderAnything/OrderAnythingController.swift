//
//  OrderAnythingController.swift
//  WaselDelivery
//
//  Created by sunanda on 11/9/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Unbox
import RxSwift
import AVFoundation
import SDWebImage
import MobileCoreServices

struct SpecialOrder {
    
    var items: [[String: AnyObject]] = [[NameKey: "" as AnyObject, QuantityKey: 1 as AnyObject, ProductImageKey: [String]() as AnyObject]]
    var productImagesArray: [UIImage?] = [Utilities.shared.cameraIconImage]
    var location: Address?
    var instructions: String = ""
    
    func didEditedOrder(isVendorOutLet: Bool? = false) -> Bool {
        if true == isVendorOutLet {
            return didItemsExist() || didImagesExist() || self.instructions.count > 0
        }
        return didItemsExist() || didImagesExist() || (self.location != nil) || self.instructions.count > 0
    }

    func didItemsExist() -> Bool {
        var itemExist = false
        _ = self.items.map({ (obj) -> [String: AnyObject] in
            if let name_ =  obj[NameKey] as? String, name_.count > 0 {
                itemExist = true
            }
            return obj
        })
        return itemExist
    }
    
    func didImagesExist() -> Bool {
        var imagesExist = false
        _ = self.items.map ({ (obj) -> [String: AnyObject] in
            if let images_ =  obj[ProductImageKey] as? [String], images_.count > 0 {
                imagesExist = true
            }
            return obj
        })
        return imagesExist
    }
    
    mutating func addNewItem() {
        items.append([NameKey: "" as AnyObject as AnyObject, QuantityKey: 1 as AnyObject, ProductImageKey: [String]() as AnyObject])
        productImagesArray.append(Utilities.shared.cameraIconImage)
    }
}

extension UIImage {
    func setImageWithName() {
        
    }
}

class OrderAnythingController: BaseViewController, MultiLocationPopUpProtocol {

    @IBOutlet weak var transparentView: UIView!
    @IBOutlet weak var checkoutButton: UIButton!
    @IBOutlet weak var outletBgImageView: UIImageView!
    @IBOutlet weak var specialOrderHeaderLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var outletNameLabel: UILabel!
    @IBOutlet weak var handleFeeLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var outletHeaderBgView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var timingBgView: UIView!
    @IBOutlet weak var timingLabel: UILabel!
    @IBOutlet weak var multiLocationButton: UIButton!
    @IBOutlet weak var navigationHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var orderTableView: UITableView!
    var addItemButton: UIButton!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkoutButtonBottomConstraint: NSLayoutConstraint!
    let bottomConstraintConstant: CGFloat = 79.0
    var currentIdexPath: IndexPath?
    var showNotification: Any!
    var hideNotification: Any!
    var specialOrder = SpecialOrder()
    var pickUpLocation: Address?
    var isVendorOutLet: Bool = false
    var sessionTask: URLSessionTask?
    var outlet: Outlet?
    var applyGradient = false
    var isFromSearchScreen: Bool = false
    var selectedOutletInformation: OutletsInfo?
    fileprivate var multiLocationPopUpViewController: MultiLocationPopUpViewController?
    var shouldRepeatOrder = false
    var isFromOrderDetailsScreen: Bool = false
    var selectedProductImageIndex = -1
    var currentVehicle: VehicleType = .motorbike
    var deliveryCharge: DeliveryCharge?
//    let cameraIconImage = UIImage(named: "cameraIcon")
    private var disposableBag = DisposeBag()

    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        return picker
    }()
    
    private lazy var cameraPicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        return picker
    }()
    
    var textViewSize = -1.0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: slectedPaymentMethod)
        userDefaults.synchronize()

        if let outletsArray = self.selectedOutletInformation?.outlet, 1 < outletsArray.count {
            multiLocationPopUpViewController = MultiLocationPopUpViewController(nibName: "MultiLocationPopUpViewController", bundle: .main)
            multiLocationButton.isHidden = false
            if true == isFromSearchScreen {
                self.showMultilocationPopUp(multiLocationButton)
            }
        } else {
            multiLocationButton.isHidden = true
        }
        NotificationCenter.default.addObserver(self, selector: #selector(updateAppOpenCloseStateUI), name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)

        orderTableView.register(UINib(nibName: "OrderAnythingHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "OrderAnythingHeaderView")
        
        orderTableView.estimatedRowHeight = 96.0
        orderTableView.rowHeight = UITableView.automaticDimension
        self.addNavigationView()
        navigationView?.backButton.isHidden = !isVendorOutLet
        navigationView?.editButton.isHidden = false
        navigationView?.editButton.setTitle("Clear", for: .normal)
        navigationView?.editButton.titleLabel?.font = UIFont.montserratSemiBoldWithSize(14.0)
        navigationView?.editButton.setTitleColor(UIColor(red: (60.0/255.0), green: (60.0/255.0), blue: (60.0/255.0), alpha: 1.0), for: .normal)
        navigationView?.editButton.setTitleColor(UIColor.unSelectedTextColor(), for: .disabled)
        navigationView?.editButton.setImage(nil, for: .normal)
        navigationView?.editButton.isEnabled = false
        
        if let imageUrl_ = outlet?.imageUrl, imageUrl_.count > 0, true == isVendorOutLet {
            outletBgImageView.sd_setImage(with: URL(string: imageUrl_), placeholderImage: UIImage(named: "outlet_placeholder"))
        } else {
            let imageName = (true == isVendorOutLet) ? "outlet_placeholder" : "orderAnythingImage"
            outletBgImageView.image = UIImage(named: imageName)
        }
        self.specialOrderHeaderLabel.isHidden = isVendorOutLet

        if isVendorOutLet {
            outletHeaderBgView.isHidden = false
            if let outlet_ = outlet {
                distanceLabel.attributedText = Utilities.getDistanceAttString(outlet: outlet_)
                if true == outlet?.isFleetOutLet {
                    costLabel.attributedText = NSAttributedString(string: outlet?.ownFleetDescription ?? "")
                } else {
                    costLabel.attributedText = Utilities.getDeliveryChargeAttString(outlet: outlet_)
                }

                var pricesString = ""
                let handlingFeeString = Utilities.getHandleFeeStringFrom(outlet: outlet_)
                if outlet_.showVendorMenu ?? false {
                    let minOrderString = Utilities.getMinimumOrderStringFrom(outlet: outlet_)
                    pricesString += minOrderString.isEmpty ? "" : minOrderString
                }

                infoButton.isHidden = true
                if !handlingFeeString.isEmpty {
                    pricesString += pricesString.isEmpty ? "" : " | "
                    pricesString += handlingFeeString
                    infoButton.isHidden = false
                }
                handleFeeLabel.text = pricesString

                let outletName = Utilities.fetchOutletName(outlet_)
                self.outletNameLabel.text = outletName
            } else {
                let emptyString = NSAttributedString(string: "")
                distanceLabel.attributedText = emptyString
                costLabel.attributedText = emptyString
                handleFeeLabel.text = ""
                self.outletNameLabel.text = ""
                infoButton.isHidden = true
            }
            self.navigationView?.titleLabel.text = ""
            gradientView.isHidden = false
        } else {
            outletHeaderBgView.isHidden = true
            self.navigationView?.titleLabel.text = "Order Anything"
            gradientView.isHidden = true
        }
        
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkoutButton.isEnabled = isAppOpen
        self.loadTimings()
        
        if true == Utilities.shared.isIphoneX() {
            checkoutButtonBottomConstraint.constant = 10.0
        } else {
            checkoutButtonBottomConstraint.constant = 34.0
        }
        
        if isVendorOutLet {
            if let outlet_ = outlet {
                let outletName = Utilities.fetchOutletName(outlet_)
                self.outletNameLabel.text = outletName
                let isPartnerFlag = (outlet_.isPartnerOutLet ?? false) ? "Yes" : "No"
                let ownDeliveryStatus = (outlet_.isFleetOutLet ?? false) ? "Yes" : "No"
                let params: [String: Any] = [
                    "StoreName": outletName,
                    "StoreID": String(outlet_.id ?? 0),
                    "CategoryName": outlet_.amenity?.name ?? "",
                    "CategoryID": outlet_.amenity?.id ?? "",
                    "DeliveryCharge": outlet_.deliveryCharge ?? 0.0,
                    "Partner": isPartnerFlag,
                    "Distance": outlet_.distance ?? 0.0,
                    "OwnDelivery": ownDeliveryStatus,
                    "CartID": Utilities.shared.cartId ?? ""
                ]
                UPSHOTActivitySetup.shared.createCustomTimedEvent(eventName: BKConstants.VIEW_STORE_ORDER_EVENT, params: params)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let userDefaults = UserDefaults.standard
        let isTutorialCompleted_ = userDefaults.bool(forKey: isTutorialCompleted)
        if false == isTutorialCompleted_ {
            let tutorialPageController = TutorialPageController.instantiateFromStoryBoard(.main)
            self.navigationController?.present(tutorialPageController, animated: true, completion: nil)
        }
        
        navigationHeightConstraint.constant = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
        registerForKeyBoardNotification()
        orderTableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(checkOut(_:)), name: NSNotification.Name(rawValue: ProceedToCheckOutNotification), object: nil)
        if true == isVendorOutLet {
            if true == shouldRepeatOrder {
                self.loadRestaurantAddressDetails(isRepeatOrder: false, completionHandler: { (isRestaurantDetailsFetched) in
                    if true == isRestaurantDetailsFetched {
                        if true == self.shouldRepeatOrder {
                            self.loadRestaurantAddressDetails(isRepeatOrder: true, completionHandler: { (isOutDetailsFetched) in
                                if true == isOutDetailsFetched {
                                }
                                self.getDeliveryChargesWithVehicles()
                            })
                        }
                    }
                })
            } else {
                self.loadRestaurantAddressDetails(completionHandler: { _ in
                    self.getDeliveryChargesWithVehicles()
                })
            }
        }
        Utilities.showTransparentView(isFromOrderAnythingScreen: true)
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkoutButton.backgroundColor = UIColor(red: (85.0/255.0), green: (190.0/255.0), blue: (109.0/255.0), alpha: isAppOpen ? 1.0
            : 0.5)
        transparentView.isHidden = isAppOpen
        Utilities.shared.currentOutlet = self.outlet
    }
    
    func getDeliveryChargesWithVehicles() {
        if Utilities.getUser() != nil {
            Utilities.showHUD(to: self.view, "")
            var requestObj: [String: Any] = [:]
            let userLocation = Utilities.getUserLocation()
            requestObj["latitude"] = userLocation?.latitude ?? 0.0
            requestObj["longitude"] = userLocation?.longitude ?? 0.0
            requestObj["outletLatitude"] = self.specialOrder.location?.latitude ?? 0.0
            requestObj["outletLongitude"] = self.specialOrder.location?.longitude ?? 0.0
            requestObj["orderType"] = OrderType.special.rawValue
            
            ApiManager.shared.apiService.deliveryChargesByVehicleType(requestObj as [String: AnyObject]).subscribe(
                onNext: { [weak self](deliveryChargeObj) in
                    Utilities.hideHUD(from: self?.view)
                    self?.deliveryCharge = deliveryChargeObj
                    self?.orderTableView.reloadData()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        NotificationCenter.default.removeObserver(showNotification)
        NotificationCenter.default.removeObserver(hideNotification)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ProceedToCheckOutNotification), object: nil)
        Utilities.showTransparentView(shouldShowTransparentBg: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UPSHOTActivitySetup.shared.createPageViewEvent(currentPage: BKConstants.ORDER_ANYTHING_SCREEN)
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: BKConstants.ORDERANYTHING_SCREEN_TAG)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if applyGradient == false {
            applyGradient = true
            let gradient1: CAGradientLayer = CAGradientLayer()
            gradient1.frame.size = CGSize(width: ScreenWidth, height: gradientView.frame.size.height)
            gradient1.colors = [UIColor(red: (56.0/255.0), green: (56.0/255.0), blue: (56.0/255.0), alpha: 0.0).cgColor, UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.9).cgColor]
            gradientView.layer.addSublayer(gradient1)
        }
    }
    
    override func navigateBack(_ sender: Any?) {
        if let sessionTask_ = sessionTask {
            sessionTask_.cancel()
        }
        view.endEditing(true)
        if true == isVendorOutLet {
            if specialOrder.didEditedOrder(isVendorOutLet: true) {
                let popupVC = PopupViewController()
                let messageString = NSLocalizedString("Do you want to discard your Order?", comment: "")
                let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: messageString, buttonText: "Cancel", cancelButtonText: "Clear")
                responder.addCancelAction({
                    DispatchQueue.main.async(execute: {
                        UPSHOTActivitySetup.shared.closeEvent(eventId: BKConstants.VIEW_STORE_ORDER_EVENT)
                        Utilities.shouldHideTabCenterView(self.tabBarController, false)
                        if true == self.isFromOrderDetailsScreen {
                            if let aViewController = self.navigationController?.viewControllers[1] {
                                self.navigationController?.popToViewController(aViewController, animated: true)
                            } else {
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        } else {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    })
                })
            } else {
                UPSHOTActivitySetup.shared.closeEvent(eventId: BKConstants.VIEW_STORE_ORDER_EVENT)
                Utilities.shouldHideTabCenterView(self.tabBarController, false)
                if true == self.isFromOrderDetailsScreen {
                    if let aViewController = self.navigationController?.viewControllers[1] {
                        self.navigationController?.popToViewController(aViewController, animated: true)
                    } else {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                } else {
                    self.navigationController?.popToRootViewController(animated: true)
                }

                // clear cartID
                Utilities.shared.cartId = nil
            }
        } else if specialOrder.didEditedOrder(isVendorOutLet: isVendorOutLet) {
            let popupVC = PopupViewController()
            let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "Do you want to discard your Special Order?", buttonText: "Cancel", cancelButtonText: "Clear")
            responder.addCancelAction({
                DispatchQueue.main.async(execute: {
                    self.clearOrder()
                })
            })
        }
    }
    
    override func editAction(_ sender: UIButton?) {
        view.endEditing(true)
        if specialOrder.didEditedOrder(isVendorOutLet: isVendorOutLet) {
            let popupVC = PopupViewController()
            var messageString = NSLocalizedString("Do you want to discard your Special Order?", comment: "")
            if true == isVendorOutLet {
                messageString = NSLocalizedString("Do you want to discard your Order?", comment: "")
            }
            let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: messageString, buttonText: "Cancel", cancelButtonText: "Clear")
            responder.addCancelAction({
                DispatchQueue.main.async(execute: {
                    self.clearOrder()
                })
            })
        }
    }
    
    @IBAction func showHandlingFeeInfo(_ sender: UIButton) {
        let controller = HandlingFeeInfoViewController.instantiateFromStoryBoard(.main)
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .overCurrentContext

        DispatchQueue.main.async {
            self.present(controller, animated: true, completion: nil)
        }
    }

    @IBAction func showMultilocationPopUp(_ sender: Any) {
        if let outletsArray = self.selectedOutletInformation?.outlet, 1 < outletsArray.count {
            view.endEditing(true)
            multiLocationPopUpViewController?.delegate = self
            if let selectedOutletIndex = self.selectedOutletInformation?.selectedOutletIndex, -1 == selectedOutletIndex, true == isFromSearchScreen {
                self.selectedOutletInformation?.selectedOutletIndex = 0
            }
            multiLocationPopUpViewController?.selectedOutletInformation = self.selectedOutletInformation
            multiLocationPopUpViewController?.modalPresentationStyle = .overCurrentContext
            self.multiLocationPopUpViewController?.loadData()
            if let multiLocationPopUpViewController_ = multiLocationPopUpViewController {
                self.tabBarController?.present(multiLocationPopUpViewController_, animated: true, completion: nil)
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
        
        if let aOutletId = selectedOutlet.id {
            self.loadOutletDetails(outletId: aOutletId, completionHandler: { (isOutletDetailsFetched, outlet_) in
                if true == isOutletDetailsFetched {
                    if false == outlet_?.showVendorMenu { //isPartnerOutLet
                        if self.specialOrder.didEditedOrder(isVendorOutLet: self.isVendorOutLet) {
                            let popupVC = PopupViewController()
                            let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "When you leave this place cart will be cleared. Do you want to clear?", buttonText: "Cancel", cancelButtonText: "Clear")
                            responder.addCancelAction({
                                DispatchQueue.main.async(execute: {
                                    self.clearOrder()
                                    self.isVendorOutLet = true
                                    self.removeMultiLocationPopUp()
                                    self.outlet = selectedOutlet
                                    self.updateOutletDetails()
                                })
                            })
                        } else {
                            let controller = OrderAnythingController.instantiateFromStoryBoard(.main)
                            controller.outlet = selectedOutlet
                            controller.isVendorOutLet = true
                            controller.selectedOutletInformation = outletsInfo_
                            self.removeMultiLocationPopUp()
                            self.navigationController?.pushViewController(controller, animated: true)
                        }
                    } else {
                        // send event to UPSHOT before clearing cart
                        let params = ["CartID": self.getCartId()]
                        UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CLEAR_CART_EVENT, params: params)

                        Utilities.shared.clearCart()
                        self.removeMultiLocationPopUp()
                        let storyBoard = Utilities.getStoryBoard(forName: .main)
                        if let controller = storyBoard.instantiateViewController(withIdentifier: "OutletDetailsViewController") as? OutletDetailsViewController {
                            controller.outlet = selectedOutlet
                            controller.selectedOutletInformation = outletsInfo_
                            controller.loadRestaurantDetails { (isRestaurantDetailsFetched, _) in
                                if true == isRestaurantDetailsFetched {
                                    controller.isFromSearchScreen = false
                                    self.navigationController?.pushViewController(controller, animated: true)
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    func updateOutletDetails() {
        if let imageUrl_ = outlet?.imageUrl, imageUrl_.count > 0, true == isVendorOutLet {
            outletBgImageView.sd_setImage(with: URL(string: imageUrl_), placeholderImage: UIImage(named: "outlet_placeholder"))
        } else {
            let imageName = (true == isVendorOutLet) ? "outlet_placeholder" : "orderAnythingImage"
            outletBgImageView.image = UIImage(named: imageName)
        }
        self.specialOrderHeaderLabel.isHidden = isVendorOutLet
        
        if isVendorOutLet {
            outletHeaderBgView.isHidden = false
            if let outlet_ = outlet {
                distanceLabel.attributedText = Utilities.getDistanceAttString(outlet: outlet_)
                
                if true == outlet?.isFleetOutLet {
                    costLabel.attributedText = NSAttributedString(string: outlet?.ownFleetDescription ?? "")
                } else {
                    costLabel.attributedText = Utilities.getDeliveryChargeAttString(outlet: outlet_)
                }

                var pricesString = ""
                let handlingFeeString = Utilities.getHandleFeeStringFrom(outlet: outlet_)
                if outlet_.showVendorMenu ?? false {
                    let minOrderString = Utilities.getMinimumOrderStringFrom(outlet: outlet_)
                    pricesString += minOrderString.isEmpty ? "" : minOrderString
                }

                infoButton.isHidden = true
                if !handlingFeeString.isEmpty {
                    pricesString += pricesString.isEmpty ? "" : " | "
                    pricesString += handlingFeeString
                    infoButton.isHidden = false
                }
                handleFeeLabel.text = pricesString

                let outletName = Utilities.fetchOutletName(outlet_)
                self.outletNameLabel.text = outletName
            } else {
                let emptyString = NSAttributedString(string: "")
                distanceLabel.attributedText = emptyString
                costLabel.attributedText = emptyString
                handleFeeLabel.text = ""
                self.outletNameLabel.text = ""
                infoButton.isHidden = true
            }
            self.navigationView?.titleLabel.text = ""
            gradientView.isHidden = false
        } else {
            outletHeaderBgView.isHidden = true
            self.navigationView?.titleLabel.text = "Order Anything"
            gradientView.isHidden = true
        }
        
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkoutButton.isEnabled = isAppOpen
        self.loadTimings()
    }

    // MARK: - Notification Refresh methods
    
    @objc private func updateAppOpenCloseStateUI() {
        Utilities.showTransparentView()
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkoutButton.backgroundColor = UIColor(red: (85.0/255.0), green: (190.0/255.0), blue: (109.0/255.0), alpha: isAppOpen ? 1.0
            : 0.5)
        transparentView.isHidden = isAppOpen
        checkoutButton.isEnabled = isAppOpen
        UIView.performWithoutAnimation {
            self.orderTableView.reloadData()
        }
    }

    // MARK: - API Methods

    fileprivate func loadRestaurantAddressDetails(isRepeatOrder: Bool? = false, completionHandler: ((_ isRestaurantDetailsFetched: Bool) -> Void)? = nil) {
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        var path = URI.outletItems.rawValue + "\(outlet?.id ?? 0)"
        if true == isRepeatOrder {
            guard let userLocation = Utilities.getUserLocation() else {
                Utilities.showToastWithMessage("Please select location.")
                return
            }
            let latitude = userLocation.latitude as AnyObject
            let longitude = userLocation.longitude as AnyObject
            let secondsFromGMT = NSTimeZone.local.secondsFromGMT() as AnyObject
            path = URI.outletItems.rawValue + "\(outlet?.id ?? 0)" + "/\(latitude)" + "/\(longitude)" + "/\(secondsFromGMT)"
        }
//        let path = URI.outletItems.rawValue + "\(outlet?.id ?? 0)"
        let request = ApiManager.clientURLRequest(path, method: .get)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        Utilities.showHUD(to: view, "Loading...")
        
        if ApiManager.shared.apiServiceType == .apiService {
            sessionTask = session.dataTask(with: request as URLRequest) { (data, response, _) -> Void in
                DispatchQueue.main.async {
                    Utilities.hideHUD(from: self.view)
                    let response = response as? HTTPURLResponse
                    if let response_ = response {
                        if response_.statusCode == ResponseStatusCode.success.rawValue {
                            if let data_ = data {
                                do {
                                    let json = try JSONSerialization.jsonObject(with: data_, options: .mutableContainers) as AnyObject
                                    Utilities.log(json as AnyObject, type: .info)
                                    if let json_ = json as? [String: AnyObject] {
                                        if let addressDict = json_["address"] as? [String: AnyObject] {
                                            do {
                                                let address_: Address = try unbox(dictionary: addressDict)
                                                self.specialOrder.location = address_
                                                self.orderTableView.reloadData()
                                            } catch {}
                                        }
                                        if true == self.isVendorOutLet {
                                            if true == isRepeatOrder {
                                                let outletsInfo: OutletsInfo = try unbox(dictionary: json_)
                                                if let outlet_: Outlet = outletsInfo.outlet?.first {
                                                    self.updateOutletHeaderDetails(outlet_: outlet_)
                                                }
                                            } else {
                                                self.parseOutlet(json_: json_)
                                            }
                                            if let acompletionHandler = completionHandler {
                                                acompletionHandler(true)
                                            }
                                        }
                                    }
                                } catch {}
                            }
                        }
                    }
                }
            }
            sessionTask?.resume()
        }
    }
    
    private func parseOutlet(json_: [String: AnyObject]) {
        do {
            let distance = self.outlet?.distance
            let deliveryCharge = self.outlet?.deliveryCharge
            let timing = self.outlet?.timing
            let firstShiftStartTime = self.outlet?.firstShiftStartTime
            let firstShiftEndTime = self.outlet?.firstShiftEndTime
            let secondShiftStartTime = self.outlet?.secondShiftStartTime
            let secondShiftEndTime = self.outlet?.secondShiftEndTime
            
            let outlet_: Outlet = try unbox(dictionary: json_)
            self.outlet = outlet_
            self.outlet?.distance = distance
            self.outlet?.deliveryCharge = deliveryCharge
            self.outlet?.timing = timing
            self.outlet?.firstShiftStartTime = firstShiftStartTime
            self.outlet?.firstShiftEndTime = firstShiftEndTime
            self.outlet?.secondShiftStartTime = secondShiftStartTime
            self.outlet?.secondShiftEndTime = secondShiftEndTime
            
            Utilities.shared.currentOutlet = self.outlet
        } catch {}
    }
    
    func updateOutletHeaderDetails(outlet_: Outlet) {
        self.outlet?.distance = outlet_.distance
        self.outlet?.deliveryCharge = outlet_.deliveryCharge
        self.outlet?.timing = outlet_.timing
        self.outlet?.firstShiftStartTime = outlet_.firstShiftStartTime
        self.outlet?.firstShiftEndTime = outlet_.firstShiftEndTime
        self.outlet?.secondShiftStartTime = outlet_.secondShiftStartTime
        self.outlet?.secondShiftEndTime = outlet_.secondShiftEndTime
        self.outlet?.openStatus = outlet_.openStatus
        self.outlet?.opentime = outlet_.opentime
        self.updateOutletDetails()
    }
    
    fileprivate func loadTimings() {
        if true == isVendorOutLet {
            timingBgView.isHidden = false
            if let aOutLet = self.outlet {
                let outletStatus = Utilities.isOutletOpen(aOutLet)
                timingLabel.text = outletStatus.message
            } else {
                timingBgView.isHidden = true
                timingLabel.text = ""
            }
        } else {
            timingLabel.text = ""
            timingBgView.isHidden = true
        }
    }
    
// MARK: - IBActions
    
    @objc func addItemRow() {
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        if false == isAppOpen {
            return
        }
        let aIndexPath = IndexPath(row: specialOrder.items.count - 1, section: 1)
        specialOrder.addNewItem()
        orderTableView.beginUpdates()
        orderTableView.insertRows(at: [aIndexPath], with: .automatic)
        orderTableView.endUpdates()
        
        orderTableView.reloadData()
        self.orderTableView.scrollToRow(at: aIndexPath, at: .middle, animated: false)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(200)) {
            if let currentCell = self.orderTableView.cellForRow(at: IndexPath(row: self.specialOrder.items.count - 1, section: 1)) as? OrderAnyThingCell {
                currentCell.orderTextView.becomeFirstResponder()
            } else {
                if let tableFooterView_ = self.orderTableView.tableFooterView {
                    self.orderTableView.scrollRectToVisible(tableFooterView_.frame, animated: true)
                }
            }
            self.addItemButton.isHidden = (self.specialOrder.items.count == 50) ? true : false
        }
    }
    
    @IBAction func checkOut(_ sender: Any) {
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        checkoutButton.isEnabled = isAppOpen
        if false == isAppOpen {
            return
        }

        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }

        view.endEditing(true)
        if currentIdexPath != nil {
            currentIdexPath = nil
        }
        
        validateOrder()

        guard specialOrder.location != nil && specialOrder.location?.latitude != 0.0 && specialOrder.location?.longitude != 0.0 else {
            Utilities.showToastWithMessage("Please add pickup location.")
            return
        }
        
        let itemsWithTitlesCount = specialOrder.items.filter { (($0[NameKey] as? String) ?? "").count > 0 }.count
        
        if specialOrder.items.count != itemsWithTitlesCount {
            Utilities.showToastWithMessage("Please add items.")
            return
        }

        guard Utilities.getUser() != nil else {
            if false == Utilities.isWaselDeliveryOpen() {
                return
            }
            let loginVC = LoginViewController.instantiateFromStoryBoard(.login)
            loginVC.isFromCheckout = true
            let navController = UINavigationController(rootViewController: loginVC)
            navController.isNavigationBarHidden = true
            self.navigationController?.present(navController, animated: true, completion: nil)
            return
        }
        
        let params: [String: Any] = [
            "ItemsCount": specialOrder.items.count,
            "Instructions": specialOrder.instructions,
            "Type": "OrderAnything",
            "ConfirmLocation": "Yes",
            "CartID": getCartId()
        ]
        UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CHECKOUT_EVENT, params: params)

        let checkoutSB = Utilities.getStoryBoard(forName: .checkOut)
        if let checkoutController = checkoutSB.instantiateViewController(withIdentifier: "ConfirmOrderController") as? ConfirmOrderController {
            
            // Sending item name and image statu to upshot
            for item in specialOrder.items {
                let name_ = item[NameKey] as? String ?? ""
                let isImageUploaded_ = (item[ProductImageKey] as? [String])?.first?.isEmpty ?? false
                let params: [String: Any] = [
                    "ItemName": name_,
                    "Photo": (true == isImageUploaded_) ? "Yes" : "No",
                    "IsFromOrderAnything": (true == self.isVendorOutLet) ? "No" : "Yes",
                    "CartID": getCartId()
                ]
                UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.ORDERANYTHING_EVENT, params: params)
            }

            checkoutController.specialOrder = specialOrder
            checkoutController.vehicleType = currentVehicle
            checkoutController.shouldRepeatOrder = self.shouldRepeatOrder
            checkoutController.orderType = .special
            checkoutController.isVendorOutLet = self.isVendorOutLet
            if true == isVendorOutLet, let aOutlet = self.outlet {
                checkoutController.outlet = aOutlet
            }
            let cartNavController = UINavigationController(rootViewController: checkoutController)
            cartNavController.isNavigationBarHidden = true
            navigationController?.present(cartNavController, animated: true, completion: nil)
        }
    }
    
    @IBAction func done(_ sender: Any) {
        view.endEditing(true)
        UIView.performWithoutAnimation {
            self.orderTableView.reloadData()
        }
    }
    
// MARK: - Support Methods
    
    private func validateOrder() {
        specialOrder.items = specialOrder.items.filter { (($0[NameKey] as? String) ?? "").count > 0 || (($0[ProductImageKey] as? [String])?.count ?? 0) > 0}
        if specialOrder.items.count == 0 {
            specialOrder.items = [[NameKey: "" as AnyObject, QuantityKey: 1 as AnyObject, ProductImageKey: [String]() as AnyObject]]
        }
        orderTableView.reloadData()
    }
    
    func registerForKeyBoardNotification() {
        
        showNotification = registerForKeyboardDidShowNotification(tableBottomConstraint, bottomConstraintConstant, shouldUseTabHeight: !isVendorOutLet, usingBlock: { _ in
            DispatchQueue.main.async(execute: {
                if let currentIdexPath_ = self.currentIdexPath {
                    self.orderTableView.scrollToRow(at: currentIdexPath_, at: .middle, animated: false)
                }
            })
        })
        hideNotification = registerForKeyboardWillHideNotification(tableBottomConstraint, bottomConstraintConstant)
    }
    
    func clearOrder() {
        // clear cart ID
        Utilities.shared.cartId = nil
        if specialOrder.didEditedOrder(isVendorOutLet: isVendorOutLet) == true {
            navigationView?.editButton.isEnabled = false
            if true == isVendorOutLet {
                let location = self.specialOrder.location
                self.specialOrder = SpecialOrder()
                self.specialOrder.location = location
            } else {
                self.specialOrder = SpecialOrder()
            }
            self.orderTableView.reloadData()
            self.currentIdexPath = nil
            
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: slectedPaymentMethod)
            userDefaults.synchronize()
        }
    }

    private func getCartId() -> String {
        if let cartId = Utilities.shared.cartId {
            return cartId
        } else {
            Utilities.shared.cartId = UUID().uuidString
            return Utilities.shared.cartId ?? ""
        }
    }
    
    // MARK: User Defined Methods
    
    func showCamera() {
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .authorized:
            self.present(self.cameraPicker, animated: true, completion: nil)
        case .denied:
            alertToAccessCamera()
        case .notDetermined:
            requestCameraAccess()
        case .restricted:
            alertToAccessCamera()
        }
    }
    
    func alertToAccessCamera() {
        let alert = UIAlertController(
            title: "Wasel Delivery",
            message: "Camera access required for capturing photos.",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Allow", style: .cancel, handler: { (_) -> Void in
            UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString) ?? URL(fileURLWithPath: ""))
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func requestCameraAccess() {
        if AVCaptureDevice.devices(for: AVMediaType.video).count > 0 {
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { _ in
                DispatchQueue.main.async {
                    self.showCamera()
                }
            }
        }
    }
    
    func showPhotoLibrary() {
        self.imagePicker.mediaTypes = [kUTTypeImage as String]
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
// MARK: - PickerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        if let image_ = image {
            let resizedImage = image_.resizeImage(newWidth: 200.0)
            if -1 < selectedProductImageIndex {
                self.specialOrder.items[selectedProductImageIndex][ProductImageKey] = [String]() as AnyObject
                self.uploadImage(productImage: resizedImage, itemIndex: selectedProductImageIndex)
            }
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo: UnsafeRawPointer) {
        
        Utilities.showToastWithMessage("Failed to save image")
        if error != nil {
            let alert = UIAlertController(title: "Save Failed",
                                          message: "Failed to save image",
                                          preferredStyle: UIAlertController.Style.alert)
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel,
                                             handler: nil)
            alert.addAction(cancelAction)
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }
    
    private func uploadImage(productImage: UIImage, itemIndex: Int) {

        var requestObj: [String: Any] = [:]
//        var requestObj: [String: Any] = [UserIdKey: Utilities.shared.user!.id!]
        let image_data = productImage.jpegData(compressionQuality: 0.75)
        requestObj["imageData"] = image_data
        
        Utilities.showHUD(to: self.view, "")
        ApiManager.shared.apiService.updateProductImage(requestObj as [String: AnyObject]).subscribe(onNext: { [weak self](result) in
            
            Utilities.hideHUD(from: self?.view)
            
            self?.saveproductImageResponse(user: result, at: itemIndex, productImage: productImage)
            
            self?.specialOrder.productImagesArray[itemIndex] = productImage

            let user = result
            guard user.imageUrl != nil else {
                Utilities.showToastWithMessage("Image Upload failed")
                return
            }
            
            if let imageURL_ = user.imageUrl {
                var imagesArray = [String]()
                imagesArray.append(imageURL_ as String)
                self?.specialOrder.items[itemIndex][ProductImageKey] = imagesArray as AnyObject
            } else {
                self?.specialOrder.items[itemIndex][ProductImageKey] = [String]() as AnyObject
            }
            self?.orderTableView.reloadData()
            
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
        }).disposed(by: disposableBag)
    }
    
    func saveproductImageResponse(user: User, at index: Int, productImage: UIImage) {
        
        specialOrder.productImagesArray[index] = productImage
        
        guard user.imageUrl != nil else {
            Utilities.showToastWithMessage("Image Upload failed")
            return
        }
        
        if let imageURL_ = user.imageUrl {
            var imagesArray = [String]()
            imagesArray.append(imageURL_ as String)
            specialOrder.items[index][ProductImageKey] = imagesArray as AnyObject
        } else {
            specialOrder.items[index][ProductImageKey] = [String]() as AnyObject
        }
        navigationView?.editButton.isEnabled = (specialOrder.didEditedOrder(isVendorOutLet: isVendorOutLet) == true) ? true : false

        orderTableView.reloadData()

    }
    
}

extension OrderAnythingController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, OrderAnythingCellDelegate, UpdatePickupLocation, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = (section == 1) ? specialOrder.items.count : 1
        return count
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 1: return 45.0
        default: return 1.0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (1 == section) ? 30.0 : 46.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            if let address_ = specialOrder.location, let location_ = address_.location?.trim(), location_.length > 0 {
                var height_ = Utilities.getSizeForText(text: location_, font: .montserratLightWithSize(14.0), fixedWidth: ScreenWidth - 55.0).height
                if height_ < 28.0 {
                    height_ = 28.0
                }
                height_ += 17.0
                return height_
            } else {
                return 46.0
            }
        } else if indexPath.section == 2 {
            return 120
        }
        return tableView.rowHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "OrderAnythingHeaderView") as? OrderAnythingHeaderView
        var titleText = ""
        switch section {
        case 0: titleText = "Pickup Location"
        case 1: titleText = "Items"
        case 2: titleText = "Choose your Vehicle"
        case 3: titleText = "Order / Delivery Instruction"
        default: return nil
        }
        header?.updateTitle(title: titleText, shouldShowSeperator: false)
        return header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == 1 else {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 1))
            view.backgroundColor = .clear
            return view
        }
        let aView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: ScreenWidth, height: 45.0))
        aView.backgroundColor = .white
        addItemButton = UIButton(frame: CGRect(x: 20.0, y: 0.0, width: 88.0, height: 45.0))
        addItemButton.setTitle("+ Add Item", for: .normal)
        addItemButton.titleLabel?.font = UIFont.montserratSemiBoldWithSize(16.0)
        addItemButton.addTarget(self, action: #selector(addItemRow), for: .touchUpInside)
        let isAppOpen = Utilities.isWaselDeliveryOpen()
        let titleColor = UIColor(red: 85.0/255.0, green: 190.0/255.0, blue: 109.0/255.0, alpha: isAppOpen ? 1.0 : 0.5)
        addItemButton.setTitleColor(titleColor, for: .normal)
        aView.addSubview(addItemButton)
        
        let seperatorView = UIView(frame: CGRect(x: 0.0, y: 44.0, width: ScreenWidth, height: 1.0))
        seperatorView.backgroundColor = UIColor(red: 214.0/255.0, green: 213.0/255.0, blue: 213.0/255.0, alpha: isAppOpen ? 1.0 : 0.5)
        aView.addSubview(seperatorView)

        return aView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if false == Utilities.isWaselDeliveryOpen() {
            return
        }
        if indexPath.section == 0 && outlet == nil {
            let storyboard = Utilities.getStoryBoard(forName: .checkOut)
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            if let rootNavController = appDelegate.window?.rootViewController as? UINavigationController {
                guard let addAddressController = storyboard.instantiateViewController(withIdentifier: "AddAddressController") as? AddAddressController else {
                    return
                }
                addAddressController.pickupDelegate = self
                addAddressController.isFromOrderAnyThing = true
                rootNavController.pushViewController(addAddressController, animated: true)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            guard let locationCell = tableView.dequeueReusableCell(withIdentifier: OrderAnyThingLocationCell.cellIdentifier(), for: indexPath) as? OrderAnyThingLocationCell else {
                return UITableViewCell()
            }
            locationCell.isUserInteractionEnabled = Utilities.isWaselDeliveryOpen()
            locationCell.updateLocation(address: specialOrder.location)
            return locationCell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderAnyThingCell.cellIdentifier(), for: indexPath) as? OrderAnyThingCell else {
                return UITableViewCell()
            }
            cell.isUserInteractionEnabled = Utilities.isWaselDeliveryOpen()
            cell.delegate = self
            let name_ = specialOrder.items[indexPath.row][NameKey] as? String ?? ""
            cell.updateCellWithText(text: name_, tag: indexPath.row + 1, toolbar, specialOrder.items.count)
//            if true == self.isVendorOutLet {
//                cell.resetProductImageDisplay()
//            } else {
                if indexPath.row < self.specialOrder.productImagesArray.count {
                    let productImage = self.specialOrder.productImagesArray[indexPath.row]
                    if let aImage_ = Utilities.shared.cameraIconImage, productImage == aImage_ {
                        cell.updateProductImage(productImage: aImage_, imageUrlString: nil, shouldShowProductCloseImage: false)
                    } else {
                        cell.updateProductImage(productImage: productImage, imageUrlString: nil, shouldShowProductCloseImage: true)
                    }
                } else {
                    if let aImage = Utilities.shared.cameraIconImage {
                        cell.updateProductImage(productImage: aImage, imageUrlString: nil, shouldShowProductCloseImage: false)
                    }
                }
            return cell
        case 2:
           guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderAnyThingVehicleCell.cellIdentifier(), for: indexPath) as? OrderAnyThingVehicleCell else {
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
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderAnyThingInstructionsCell.cellIdentifier(), for: indexPath) as? OrderAnyThingInstructionsCell else {
                return UITableViewCell()
            }
            cell.isUserInteractionEnabled = Utilities.isWaselDeliveryOpen()
            cell.instructionsTextView.tag = SpecialOrderInstructionsTag
            cell.keyBoardtoolBar = toolbar
            cell.instructionsTextView.text = specialOrder.instructions
            cell.showPlaceHolderInstructionLabel(shouldShowPlaceHolderLabel: specialOrder.instructions.isEmpty)
            cell.textViewDelegate = self
            return cell
        }
    }
    
    func textViewDidChangeCharacters(forTextView textView: UITextView) {
        
        if nil != specialOrder.location, false == self.isVendorOutLet {
            navigationView?.editButton.isEnabled = true
        } else {
            if textView.text.trim().isEmpty {
                if textView.tag == SpecialOrderInstructionsTag {
                    navigationView?.editButton.isEnabled = specialOrder.didItemsExist() || specialOrder.didImagesExist()
                } else if textView.tag != 1 {
                    var specialOrder_ = self.specialOrder
                    specialOrder_.items[textView.tag - 1][NameKey] = "" as AnyObject
                    navigationView?.editButton.isEnabled = specialOrder_.didItemsExist() || specialOrder.didImagesExist()
                } else {
                    navigationView?.editButton.isEnabled = specialOrder.didEditedOrder(isVendorOutLet: isVendorOutLet)
                }
            } else {
                navigationView?.editButton.isEnabled = true
            }
        }
        
        let size = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: size.width,
                                                   height: CGFloat.greatestFiniteMagnitude))
        if size.height != newSize.height {
            textViewSize = Double(newSize.height)
            UIView.setAnimationsEnabled(false)
            orderTableView.beginUpdates()
            orderTableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            orderTableView.scrollToRow(at: currentIdexPath ?? IndexPath(row: 0, section: 1), at: .middle, animated: false)
        }
    }
    
    func textViewDidBegingEditing(forTextView textView: UITextView) {
        
        textViewSize = 96.0
        var section = 0//(textView.tag == 0) ? 0 : 1
        switch textView.tag {
        case 0: section = 0
        case SpecialOrderInstructionsTag: section = 2
        default: section = 1
        }
        let row = (section == 1) ? textView.tag - 1 : 0
        currentIdexPath = IndexPath(row: row, section: section)
        orderTableView.scrollToRow(at: currentIdexPath ?? IndexPath(row: 0, section: 0), at: .middle, animated: false)
    }

    func textViewDidEndEditing(forTextView textView: UITextView) {
        
        textViewSize = -1.0
        var section = 0//(textView.tag == 0) ? 0 : 1
        switch textView.tag {
        case 0: section = 0
        case SpecialOrderInstructionsTag: section = 2
        default: section = 1
        }
        let row = (section == 1) ? textView.tag - 1 : 0
        if section == 1 {
            let text_ = textView.text ?? ""
            specialOrder.items[row][NameKey] = text_.trim() as AnyObject?
        } else if section == 2 {
            guard let text_ = textView.text else {
                return
            }
            specialOrder.instructions = text_.trim()
        }
    }
    
    func deleteRowAtIndex(_ index: Int) {
        
        view.endEditing(true)
        if specialOrder.items.count == 1 && index == 0 {
            specialOrder.items[0][NameKey] = "" as AnyObject
            orderTableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
            return
        }
        self.specialOrder.productImagesArray.remove(at: index)
        specialOrder.items.remove(at: index)
        navigationView?.editButton.isEnabled = specialOrder.didEditedOrder(isVendorOutLet: isVendorOutLet)
        orderTableView.beginUpdates()
        orderTableView.deleteRows(at: [IndexPath(row: index, section: 1)], with: .fade)
        orderTableView.endUpdates()
        orderTableView.reloadData()
        addItemButton.isHidden = (specialOrder.items.count < 50) ? false : true
    }
    
    func deleteProductImageRowAtIndex(_ index: Int) {
        if index < self.specialOrder.items.count {
            if let aImage = Utilities.shared.cameraIconImage {
                self.specialOrder.productImagesArray[index] = aImage
            }
            self.specialOrder.items[index][ProductImageKey] = [String]() as AnyObject
            self.orderTableView.reloadData()
        }
        navigationView?.editButton.isEnabled = (specialOrder.didEditedOrder(isVendorOutLet: isVendorOutLet) == true) ? true : false
    }
    
    func updateProductImageRowAtIndex(_ index: Int) {
        view.endEditing(true)
        self.selectedProductImageIndex = index
        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { (_: UIAlertAction!) -> Void in
            self.showCamera()
        })
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default, handler: { (_: UIAlertAction!) -> Void in
            self.showPhotoLibrary()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_: UIAlertAction!) -> Void in
        })
        optionMenu.addAction(cameraAction)
        optionMenu.addAction(libraryAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func updatePickupLocation(address: Address) {
        specialOrder.location = address
        navigationView?.editButton.isEnabled = (specialOrder.didEditedOrder(isVendorOutLet: isVendorOutLet) == true) ? true : false
        
        let country = specialOrder.location?.country ?? ""
        let address = specialOrder.location?.getAddressString() ?? ""
        let city = specialOrder.location?.city ?? ""
        let state = specialOrder.location?.state ?? ""
        let area = specialOrder.location?.landmark ?? ""
        let confirmLocationParams: [String: Any] = [
            "City": city,
            "State": state,
            "Country": country,
            "Area": area,
            "Address": address,
            "OrderType": "Anything",
            "CartID": getCartId()
        ]
        UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CONFIRM_LOCATION_EVENT, params: confirmLocationParams)
        getDeliveryChargesWithVehicles()
    }
    
    func selectVehicleType(_ vehicle: VehicleType) {
        self.currentVehicle = vehicle
        self.orderTableView.reloadData()
    }
}

class OrderAnyThingCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var textViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeHolderLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var orderTextView: UITextView!
    @IBOutlet weak var placeHolderLabel: UILabel!
    weak var delegate: OrderAnythingCellDelegate?

    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var productImageButton: UIButton!
    @IBOutlet weak var deleteProductImageButton: UIButton!
    @IBOutlet weak var productImageBgViewWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        orderTextView.delegate = self
        productImageButton.layer.cornerRadius = 5.0
    }
    
    class func cellIdentifier() -> String {
        return "OrderAnyThingCell"
    }
    
    func updateCellWithText(text: String, tag: Int, _ accessoryView: UIToolbar, _ totalCount: Int) {
        
        orderTextView.isUserInteractionEnabled = true
        orderTextView.text = text
        orderTextView.tag = tag
        orderTextView.inputAccessoryView = accessoryView
        placeHolderLabel.text = (tag == 1) ? (orderTextView.text.count > 0) ? "" : "White Chocolate, Large, Extra Hot" : (orderTextView.text.count > 0) ? "" : "Enter Item"
        placeHolderLabel.isHidden = (orderTextView.text.count > 0) ? true : false
        if tag == 0 {
            deleteButton.isHidden = true
        } else {
            deleteButton.isHidden = (totalCount > 1) ? false : text.trim().length > 0 ? false : true
        }
        if totalCount > 1 {
            textViewTrailingConstraint.constant = ScreenWidth - deleteButton.frame.minX //134.0//with delete button//
        } else {
            if text.trim().length > 0 {
                textViewTrailingConstraint.constant = ScreenWidth - deleteButton.frame.minX //134.0//with delete button//
            } else {
                textViewTrailingConstraint.constant = ScreenWidth - deleteButton.frame.minX - deleteButton.frame.width//94.0//without delete button
            }
        }
        self.contentView.layoutIfNeeded()
//        setImageFrame()
    }
    
    func updateProductImage(productImage: UIImage?, imageUrlString imageUrlStr: String?, shouldShowProductCloseImage shouldShowCloseImage: Bool = false) {
        self.productImageBgViewWidthConstraint.constant = 60.0
        if let imageUrl_ = imageUrlStr {
            let imageUrlStr_ = imageBaseUrl+imageUrl_
            self.productImageButton.sd_setImage(with: URL(string: imageUrlStr_), for: .normal, placeholderImage: Utilities.shared.cameraIconImage)
        } else {
            if let aImage_ = productImage {
                self.productImageButton.setImage(aImage_, for: .normal)
            } else {
                self.productImageButton.setImage(Utilities.shared.cameraIconImage, for: .normal)
            }
        }
        self.productImageButton.isHidden = false
        self.deleteProductImageButton.isHidden = !shouldShowCloseImage
    }
    
    func updateCellPickupLocation(address: Address?, tag: Int) {
        
        orderTextView.isUserInteractionEnabled = false
        orderTextView.tag = tag
        if let address_ = address, let location_ = address_.location {
            orderTextView.text = location_
            placeHolderLabel.text = (location_.count > 0) ? "" : " Anywhere in Bahrain"
        } else {
            orderTextView.text = ""
            placeHolderLabel.text = (orderTextView.text.count > 0) ? "" : " Anywhere in Bahrain"
        }
        placeHolderLabel.isHidden = (true == placeHolderLabel.text?.isEmpty) ? true : false
        deleteButton.isHidden = true
        setImageFrame()
    }
    
    func updateCellWithInstructions(text: String, tag: Int, _ accessoryView: UIToolbar) {
        orderTextView.isUserInteractionEnabled = true
        orderTextView.text = text
        orderTextView.tag = tag
        orderTextView.inputAccessoryView = accessoryView
        placeHolderLabel.isHidden = (orderTextView.text.count > 0) ? true : false
        placeHolderLabel.text = (placeHolderLabel.isHidden == true) ? "" : "eg : Don’t ring the bell , Bring Change .. etc"
        deleteButton.isHidden = true
        setImageFrame()
    }
    
    func resetProductImageDisplay() {
        self.deleteProductImageButton.isHidden = true
        self.productImageButton.isHidden = true
        self.productImageBgViewWidthConstraint.constant = 0.0
    }
    
    func setImageFrame() {
        if orderTextView.tag == 0 {
            textViewLeadingConstraint.constant = 41.0
            placeHolderLeadingConstraint.constant = 44.0
        } else {
            textViewLeadingConstraint.constant = 17.0
            placeHolderLeadingConstraint.constant = 20.0
        }
        self.contentView.layoutIfNeeded()
    }
    
    @IBAction func deleteItem(_ sender: Any) {

        delegate?.deleteRowAtIndex(orderTextView.tag - 1)
    }
    
    @IBAction func deleteProductImageButtonAction(_ sender: Any) {
        delegate?.deleteProductImageRowAtIndex(orderTextView.tag - 1)
    }
    
    @IBAction func productImageButtonAction(_ sender: Any) {
        delegate?.updateProductImageRowAtIndex(orderTextView.tag - 1)
    }
    
    // MARK: UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let currentCharacterCount = textView.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + text.count - range.length
        return newLength <= MaxCharacters
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        let textLength = textView.text.count
        placeHolderLabel.isHidden = textLength > 0 ? true : false
        if textView.tag - 1 == 0 {
            if textLength > 0 {
                deleteButton.isHidden = false
                textViewTrailingConstraint.constant = ScreenWidth - deleteButton.frame.minX //134.0//with delete button//
            } else {
                deleteButton.isHidden = true
                textViewTrailingConstraint.constant = ScreenWidth - deleteButton.frame.minX - deleteButton.frame.width//94.0//without delete button
            }
            self.contentView.layoutIfNeeded()
        }
        delegate?.textViewDidChangeCharacters(forTextView: textView)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.textViewDidBegingEditing(forTextView: textView)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textViewDidEndEditing(forTextView: textView)
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.tag == 0 {
            return false
        }
        return true
    }
}

class OrderAnyThingLocationCell: UITableViewCell {
 
    @IBOutlet weak var placeHolderLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    class func nib() -> UINib {
        return UINib(nibName: "OrderAnyThingLocationCell", bundle: nil)
    }

    class func cellIdentifier() -> String {
        return "OrderAnyThingLocationCell"
    }

    func updateLocation(address: Address?) {
        if let address_ = address, let location_ = address_.location, location_.length > 0 {
            locationLabel.text = location_
            placeHolderLabel.text = ""
        } else {
            locationLabel.text = ""
            placeHolderLabel.text = " Anywhere in Bahrain"
        }
        placeHolderLabel.isHidden = (true == placeHolderLabel.text?.isEmpty) ? true : false
    }
    
}

class OrderAnyThingVehicleCell: UITableViewCell {
    
    @IBOutlet weak var motorBikeView: VehicleTypeView!
    @IBOutlet weak var carView: VehicleTypeView!
    @IBOutlet weak var truckView: VehicleTypeView!
    
    weak var vehicleDelegate: OrderAnythingCellDelegate?
    
    class func nib() -> UINib {
        return UINib(nibName: "OrderAnyThingVehicleCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "OrderAnyThingVehicleCell"
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

class OrderAnyThingInstructionsCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var placeHolderLabel: UILabel!
    @IBOutlet weak var instructionsTextView: UITextView!
    
    var keyBoardtoolBar: UIToolbar? {
        didSet {
            instructionsTextView.inputAccessoryView = keyBoardtoolBar
        }
    }
    
    weak var textViewDelegate: OrderAnythingCellDelegate?

    class func nib() -> UINib {
        return UINib(nibName: "OrderAnyThingInstructionsCell", bundle: nil)
    }
    
    class func cellIdentifier() -> String {
        return "OrderAnyThingInstructionsCell"
    }
    
    // MARK: UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let currentCharacterCount = textView.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        
        let newLength = currentCharacterCount + text.count - range.length
        return newLength <= MaxCharacters
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        let textLength = textView.text.count
        placeHolderLabel.isHidden = textLength > 0 ? true : false
        textViewDelegate?.textViewDidChangeCharacters(forTextView: textView)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textViewDelegate?.textViewDidBegingEditing(forTextView: textView)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textViewDelegate?.textViewDidEndEditing(forTextView: textView)
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.tag == 0 {
            return false
        }
        return true
    }
    
    func showPlaceHolderInstructionLabel(shouldShowPlaceHolderLabel: Bool = true) {
        placeHolderLabel.isHidden = !shouldShowPlaceHolderLabel
    }
    
}

protocol OrderAnythingCellDelegate: class {
    func textViewDidChangeCharacters(forTextView textView: UITextView)
    func textViewDidBegingEditing(forTextView textView: UITextView)
    func textViewDidEndEditing(forTextView textView: UITextView)
    func deleteRowAtIndex(_ index: Int)
    func updateProductImageRowAtIndex(_ index: Int)
    func deleteProductImageRowAtIndex(_ index: Int)
    func selectVehicleType(_ vehicle: VehicleType)
}
