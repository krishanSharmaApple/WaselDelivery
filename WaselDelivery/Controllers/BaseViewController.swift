//
//  BaseViewController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 15/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import RxSwift
import Unbox
import CoreLocation

class BaseViewController: UIViewController, Controller {
    
// MARK: - View LifeCycle
    
    var infoView: InfoDisplayView?
    var navigationView: NavigationView?
//    var sessionTask: URLSessionTask?
//    var disposbleBag = DisposeBag()

// MARK: Paytabs merchant email and secret key for live accounts
    
//    let benefitMerchantEmail = WaselDeliveryKeys().benefitMerchantEmail //"hitinder.bawani@almoayyed.com.bh"
//    let benefitSecretKey = WaselDeliveryKeys().benefitSecretKey // "VIzabFMzAbwjF3FZTHeAsIni7pe4z43vMCGYisySE5ck9Rk2yyC1h0jopxtZCxuoaansDVli0xC9pWcXvOYNPicfQFfscJRnUePy"

// Live details
//        let creditCardMerchantEmail = WaselDeliveryKeys().creditCardMerchantEmail //"hitin@waseldelivery.com"
//        let creditCardSecretKey = WaselDeliveryKeys().creditCardSecretKey // "9LEdl7fZeXKOstNvzANdMObqEZ4tQk706MdrTtq8raXTELpdlcr71CxFBC9sXht34HvXaV6C63vKOVY98ph92PPDsZ6phztlhZjr"
    
//    let creditCardMerchantEmail = "bhavani.pandranki@xcubelabs.com"
//    let creditCardSecretKey = "vovScroOIMOKDGEcq73vnTg67OWCJlFeKb7XCvLliz5VgJ8GRbcf5tlchiP1EvgpGnmjS7FaHK6XueEmqRBvkXICgyEV3UkKhG4a"
//
//    let benfitMerchantEmail = "bhavani.pandranki@xcubelabs.com"
//    let benfitSecretKey = "vovScroOIMOKDGEcq73vnTg67OWCJlFeKb7XCvLliz5VgJ8GRbcf5tlchiP1EvgpGnmjS7FaHK6XueEmqRBvkXICgyEV3UkKhG4a"

//    let benfitMerchantEmail = "sunanda.ramineni@xcubelabs.com"
//    let benfitSecretKey = "cCIFYY0oSHg3K8ogOicep2uvhm44HZKUBtzzrAYkheo2nMib5vpvyT0Pg5TY4ETG7tgz3fTkthnQ4G29bsEJlFzCLtBQ8uwgXMP0"
//
//    let creditCardMerchantEmail = "sunanda.ramineni@xcubelabs.com"
//    let creditCardSecretKey = "cCIFYY0oSHg3K8ogOicep2uvhm44HZKUBtzzrAYkheo2nMib5vpvyT0Pg5TY4ETG7tgz3fTkthnQ4G29bsEJlFzCLtBQ8uwgXMP0"

    //var initialSetupViewController: PTFWInitialSetupViewController!
    var selectedPaymentMode = PaymentsMode()
    
    fileprivate var disposeObj: Disposable?
    fileprivate var disposableBag = DisposeBag()
    
    var merchantAPI: MerchantAPI = MerchantAPI(url: URL(string: baseUrl)!)
    var gateway: Gateway = Gateway(region: .europe, merchantId: "E14305950")
    let threeDScheckAmount = "0.01"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func addNavigationView() {
        if navigationView == nil {
            navigationView = NavigationView()
            
            let navigationHeight: CGFloat = (true == Utilities.shared.isIphoneX()) ? 88.0 : 64.0
            navigationView?.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: navigationHeight)
            navigationView?.backButton.isHidden = false
            navigationView?.editButton.isHidden = true
            navigationView?.backButton.addTarget(self, action: #selector(self.navigateBack(_:)), for: .touchUpInside)
            navigationView?.editButton.addTarget(self, action: #selector(self.editAction(_:)), for: .touchUpInside)
            if let navigationView_ = navigationView {
                self.view.addSubview(navigationView_)
            }
        }
    }

    @objc func navigateBack(_ sender: Any?) {
        _ = self.navigationController?.popViewController(animated: true)
    }

    @objc func editAction(_ sender: UIButton?) {}
    
    func showInfoMessageWitType(_ infoType: InfoDisplayType) {
        createInfoView(infoType)
        if let infoView_ = infoView {
            self.view.addSubview(infoView_)
        }
    }
    
    func showServerAlert(messsage: String) {
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: messsage, buttonText: nil, cancelButtonText: "OK", attText: nil)
        responder.setCancelButtonColor(.white)
        responder.setCancelTitleColor(.unSelectedTextColor())
        responder.setCancelButtonBorderColor(.unSelectedTextColor())
    }

    func showError(_ error: Error) {
        Utilities.hideHUD(from: view)
        if let error_ = error as? ResponseError {
            if error_.getStatusCodeFromError() == .accessTokenExpire {
                
            } else {
                Utilities.showToastWithMessage(error_.description(), position: .middle)
            }
        } else {
            Utilities.showToastWithMessage(error.localizedDescription)
        }
    }
    
    func createInfoView(_ infoType: InfoDisplayType) {
        if infoView == nil {
            infoView = InfoDisplayView()
            infoView?.backgroundColor = UIColor.orange
            infoView?.frame = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 400.0)
            infoView?.center = self.view.center
        }
        infoView?.loadInfoWithType(infoType)
    }
    
    func showNoInternetMessage() {
        Utilities.showToastWithMessage("Looks like you are offline, please check internet connectivity.")
    }
    
    func getUserProfile(isSilentCall: Bool = true) -> Observable<Bool> {
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return Observable.just(false)
        }
        if isSilentCall == false {
            Utilities.showHUD(to: self.view, "")
        }
        
        return Observable.create { observer in
            ApiManager.shared.apiService.getUserProfile().subscribe(onNext: { [weak self](_) in
                Utilities.hideHUD(from: self?.view)
                return observer.onNext(true)
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
                return observer.onNext(false)
            })
        }
    }

    func getOrderDetails(orderId: Int, isSilentCall: Bool) -> Observable<Order> {
        
        if isSilentCall == false {
            Utilities.showHUD(to: self.view, "Fetching...")
        }
        
        return Observable.create { observer in
            ApiManager.shared.apiService.getOrderDetails(["id": orderId as AnyObject] as [String: AnyObject]).subscribe(
                onNext: { [weak self](order_) in
                    Utilities.hideHUD(from: self?.view)
                    return observer.onNext(order_)
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
        }
    }

    func geoCodeLocation(_ locationManager: LocationManager, _ location: CLLocation, shouldUseCurrentlocation: Bool, shouldSaveLocation: Bool = true) -> Observable<[String: AnyObject]> {
        
//        Utilities.showHUD(to: view, "Fetching Location...")
        
        return Observable.create { observer in
            locationManager.geocodeLocation(location).observeOn(MainScheduler.instance).subscribe(onNext: { (locationDict) in
                Utilities.hideHUD(from: self.view)
                if shouldSaveLocation == true {
                    Utilities.setUserLocation(locationDict, shouldUseCurrentlocation: shouldUseCurrentlocation)
                }
                return observer.onNext(locationDict)
            }, onError: { (error) in
                Utilities.hideHUD(from: self.view)
                if let error_ = error as? ResponseError {
                    Utilities.showToastWithMessage(error_.description())
                }
            })
        }
    }
    
// MARK: - Orientation Methods
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

// MARK: - LocationManagerDelegate
    
    func locationManager(_ locationManager: LocationManager, shouldShowSettingsAlert shouldShow: Bool) {
        
        if shouldShow {
            let alertViewController = UIAlertController(title: "Location Services Disabled", message: "Location services disabled for this application. Please turn on location in settings.", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString) ?? URL(fileURLWithPath: ""))
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) -> Void in
                
            }
            
            alertViewController.addAction(cancelAction)
            alertViewController.addAction(okAction)
            
            self.present(alertViewController, animated: true, completion: nil)
        }
    }

// MARK: - Update Outlet Info

    func loadOutletDetails(outletId: Int, isFromDeepLink: Bool? = false, completionHandler: ((_ isRestaurantDetailsFetched: Bool, _ outlet: Outlet?) -> Void)? = nil) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        let sessionTask: URLSessionTask?
        let disposbleBag = DisposeBag()
        let path = URI.outletItems.rawValue + "\(outletId)"
        let request = ApiManager.clientURLRequest(path, method: .get)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        if false == isFromDeepLink {
            Utilities.showHUD(to: view, "Loading...")
        }
        
        if ApiManager.shared.apiServiceType == .apiService {
            sessionTask = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
                
                DispatchQueue.main.async {
                    if false == isFromDeepLink {
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
                                        //                                    self.parseOutlet(json_: json_)
                                        let aOutlet_: Outlet = try unbox(dictionary: json_)
                                        if let acompletionHandler = completionHandler {
                                            acompletionHandler(true, aOutlet_)
                                        }
                                    }
                                } catch {
                                    if let acompletionHandler = completionHandler {
                                        Utilities.showToastWithMessage(ResponseError.parseError.description())
                                        acompletionHandler(false, nil)
                                    }
                                    //                                    self.goBackWithMessage(message: ResponseError.parseError.description())
                                }
                            } else if let error_ = error {
                                if let acompletionHandler = completionHandler {
                                    Utilities.showToastWithMessage(error_.localizedDescription)
                                    acompletionHandler(false, nil)
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
                                            acompletionHandler(false, nil)
                                        }
                                        //                                        self.goBackWithMessage(message: message)
                                    }
                                } catch {
                                    if let acompletionHandler = completionHandler {
                                        Utilities.showToastWithMessage(ResponseError.unkonownError.description())
                                        acompletionHandler(false, nil)
                                    }
                                    //                                    self.goBackWithMessage(message: (ResponseError.unkonownError.description()))
                                }
                            } else if let error_ = error {
                                if let acompletionHandler = completionHandler {
                                    Utilities.showToastWithMessage(error_.localizedDescription)
                                    acompletionHandler(false, nil)
                                }
                                //                                self.goBackWithMessage(message: error_.localizedDescription)
                            } else {
                                if let acompletionHandler = completionHandler {
                                    Utilities.showToastWithMessage(ResponseError.unkonownError.description())
                                    acompletionHandler(false, nil)
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
                                        acompletionHandler(false, nil)
                                    }
                                    //                                    self.goBackWithMessage(message: message)
                                }
                            } catch {
                                // observer.on(.error(ResponseError.unkonownError))
                            }
                        } else if let error_ = error {
                            if let acompletionHandler = completionHandler {
                                Utilities.showToastWithMessage(error_.localizedDescription)
                                acompletionHandler(false, nil)
                            }
                            //                            self.goBackWithMessage(message: error_.localizedDescription)
                        } else {
                            if let acompletionHandler = completionHandler {
                                Utilities.showToastWithMessage(ResponseError.unkonownError.description())
                                acompletionHandler(false, nil)
                            }
                            //                            self.goBackWithMessage(message: ResponseError.unkonownError.description())
                        }
                    }
                }
            }
            sessionTask?.resume()
        } else if ApiManager.shared.apiServiceType == .staticService {
            
            let outletItems = ApiManager.shared.apiService.getOutletItems(["id": "\(outletId)"])
            _ = outletItems.subscribe(onNext: { (_) in
                
//                self.filterItems(items)
                if let acompletionHandler = completionHandler {
                    acompletionHandler(false, nil)
                }
            }, onError: { (error) in
                if false == isFromDeepLink {
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
                    acompletionHandler(false, nil)
                }
            }).disposed(by: disposbleBag)
        } else {
            if false == isFromDeepLink {
                Utilities.hideHUD(from: self.view)
            }
            if let acompletionHandler = completionHandler {
                acompletionHandler(false, nil)
            }
        }
    }
    
    // MARK: Private Methods
    // MARK: Objects
    func initiatePayTabsSDK(isBenefitPay: Bool? = false, tokenString: String? = "", customerPassword: String? = "", isTokenization: Bool? = false, order_: Order? = nil, isDefaultCard: Bool? = false, shouldAddNewCard: Bool? = true, grandTotal: Float? = 0.300, isCheckOutFlow: Bool? = false, completionHandler: ((_ isCardSaved: Bool) -> Void)? = nil) {
        let resourcesBundleUrl = Bundle.main.url(forResource: "Resources", withExtension: "bundle")
        let bundle = Bundle(url: resourcesBundleUrl ?? URL(fileURLWithPath: ""))
        
//        let waselDeliveryKeys = WaselDeliveryKeys()
        var merchantEmail_ = ""//waselDeliveryKeys.creditCardMerchantEmail
        var secretKey_ = ""//waselDeliveryKeys.creditCardSecretKey
        
//        if let isBenefitPay_ = isBenefitPay, true == isBenefitPay_ {
//            merchantEmail_ = waselDeliveryKeys.benefitMerchantEmail
//            secretKey_ = waselDeliveryKeys.benefitSecretKey
//        }

        let shippingAddress = order_?.shippingAddress?.doorNumber ?? "ManamaBahrain"
        let shippingCity = order_?.shippingAddress?.landmark ?? "Manama"
        let shippingState = order_?.shippingAddress?.location ?? "Manama"
        let orderId = String(order_?.id ?? 0)
        let phoneNumber = Utilities.getUser()?.mobile ?? ""
        let email = Utilities.getUser()?.email ?? ""
//        self.initialSetupViewController = PTFWInitialSetupViewController.init(
//            nibName: "PTFWInitialSetupView",
//            bundle: bundle,
//            andWithViewFrame: self.view.frame,
//            andWithAmount: grandTotal ?? 0.300,
//            andWithCustomerTitle: "WaselDelivery",
//            andWithCurrencyCode: "BHD",
//            andWithTaxAmount: 0,
//            andWithSDKLanguage: "en",
//            andWithShippingAddress: shippingAddress,
//            andWithShippingCity: shippingCity,
//            andWithShippingCountry: "BHR",
//            andWithShippingState: shippingState,
//            andWithShippingZIPCode: "00973",
//            andWithBillingAddress: "Purpletalk",
//            andWithBillingCity: "Manama",
//            andWithBillingCountry: "BHR",
//            andWithBillingState: "Manama",
//            andWithBillingZIPCode: "00973",
//            andWithOrderID: orderId,
//            andWithPhoneNumber: phoneNumber,
//            andWithCustomerEmail: email,
//            andWithCustomerPassword: "",
//            andIsTokenization: isTokenization ?? false,
//            andIsExistingCustomer: false,
//            andWithPayTabsToken: "",
//            andWithMerchantEmail: merchantEmail_,
//            andWithMerchantSecretKey: secretKey_,
//            andWithRequestTimeoutSeconds: 0,
//            andWithAssigneeCode: "SDK")
        
        weak var weakSelf = self
//        self.initialSetupViewController.didReceiveBackButtonCallback = {
//            weakSelf?.handleBackButtonTapEvent()
//        }
        
//        self.initialSetupViewController.didReceiveFinishTransactionCallback = {(responseCode, result, transactionID, tokenizedCustomerEmail, tokenizedCustomerPassword, token, transactionState) in
//            debugPrint("responseCode: \(responseCode)")
//            debugPrint("result: \(result)")
//            debugPrint("transactionID: \(transactionID)")
//            debugPrint("tokenizedCustomerEmail: \(tokenizedCustomerEmail)")
//            debugPrint("tokenizedCustomerPassword: \(tokenizedCustomerPassword)")
//            debugPrint("transactionState: \(transactionState)")
//            debugPrint("token: \(token)")
//
//            weakSelf?.handleBackButtonTapEvent()
//
//            let transactionID_ = String(transactionID)
//
//            if let isBenefitPay_ = isBenefitPay, true == isBenefitPay_ {
//                let orderId_ = order_?.id ?? 0
//                if 0 < orderId_ {
//                    self.updateTransactionStatus(tokenString: token, tokenizedCustomerEmail: tokenizedCustomerEmail, customerPassword: tokenizedCustomerPassword, transactionId: String(transactionID_), responseCode: Int(responseCode), order_: order_, completionHandler: { (isPaymentUpdated) in
//                        if true == isPaymentUpdated {
//                            if let acompletionHandler = completionHandler {
//                                acompletionHandler(true)
//                            }
//                            return
//                        } else {
//                            Utilities.showToastWithMessage("Something went wrong.")
//                            if let acompletionHandler = completionHandler {
//                                acompletionHandler(false)
//                            }
//                            return
//                        }
//                    })
//                } else {
//                    if let acompletionHandler = completionHandler {
//                        acompletionHandler(false)
//                    }
//                }
//                return
//            } else if (false == token.isEmpty) && (false == tokenizedCustomerPassword.isEmpty) && (false == tokenizedCustomerEmail.isEmpty) && (false == transactionID_.isEmpty) {
//
//                if false == shouldAddNewCard {
//                    self.saveCard(customerEmail: tokenizedCustomerEmail, customerPassword: tokenizedCustomerPassword, isDefaultCard: isDefaultCard ?? false, token: token, transactionId: transactionID_, completionHandler: { (isCardSaved) in
//                        if true == isCardSaved {
//                            if let acompletionHandler = completionHandler {
//                                acompletionHandler(true)
//                            }
//                            return
//                        } else {
//                            Utilities.showToastWithMessage("Something went wrong.")
//                        }
//                    })
//                } else {
//                    if true == isCheckOutFlow {
//                        let orderId_ = order_?.id ?? 0
//                        if 0 < orderId_ {
//                            self.updateTransactionStatus(tokenString: token, tokenizedCustomerEmail: tokenizedCustomerEmail, customerPassword: tokenizedCustomerPassword, transactionId: String(transactionID_), responseCode: Int(responseCode), order_: order_, completionHandler: { (isPaymentUpdated) in
//                                if true == isPaymentUpdated {
//                                    if let acompletionHandler = completionHandler {
//                                        acompletionHandler(true)
//                                    }
//                                    return
//                                } else {
//                                    Utilities.showToastWithMessage("Something went wrong.")
//                                    if let acompletionHandler = completionHandler {
//                                        acompletionHandler(false)
//                                    }
//                                    return
//                                }
//                            })
//                        } else {
//                            if let acompletionHandler = completionHandler {
//                                acompletionHandler(false)
//                            }
//                        }
//                        return
//                    }
//                    self.prepareTransaction(tokenString: token, tokenizedCustomerEmail: tokenizedCustomerEmail, customerPassword: tokenizedCustomerPassword, order_: order_, grandTotal: grandTotal, completionHandler: { (isTransactionCompleted) in
//                        if true == isTransactionCompleted {
//                            let orderId_ = order_?.id ?? 0
//                            if 0 < orderId_ {
//                                if let acompletionHandler = completionHandler {
//                                    acompletionHandler(isTransactionCompleted)
//                                }
//                                return
//                            }
//
//                            self.saveCard(customerEmail: tokenizedCustomerEmail, customerPassword: tokenizedCustomerPassword, isDefaultCard: isDefaultCard ?? false, token: token, transactionId: transactionID_, completionHandler: { (isCardSaved) in
//                                if true == isCardSaved {
//                                    if let acompletionHandler = completionHandler {
//                                        acompletionHandler(true)
//                                    }
//                                    return
//                                } else {
//                                    Utilities.showToastWithMessage("Something went wrong.")
//                                    if let acompletionHandler = completionHandler {
//                                        acompletionHandler(isTransactionCompleted)
//                                    }
//                                }
//                            })
//                        } else {
//                            Utilities.showToastWithMessage("Something went wrong.")
//                            if let acompletionHandler = completionHandler {
//                                acompletionHandler(isTransactionCompleted)
//                            }
//                        }
//                    })
//                }
//            }
//        }
    }
    
    func makePayment(paymentToken: String?, sessionId: String?, threeDSecureId: String?, orderId: String, transactionId: String, amount: String, currency: String, completionHandler: @escaping ((_ success: Bool) -> Void)) {
        Utilities.showHUD(to: self.view, "")

        self.merchantAPI.makePaymentWithToken(paymentToken: paymentToken, sessionId: sessionId, threeDSecureId: threeDSecureId, orderId: String(orderId), transactionId: transactionId, amount: amount, currency: currency) { (result) in

            guard case .success(let response) = result,
                "SUCCESS" == response[at: "gatewayResponse.result"] as? String else {
                // if anything was missing, flag the step as having errored
                print("Transaction failed.")

                DispatchQueue.main.async {
                    Utilities.hideHUD(from: self.view)
                    Utilities.showMasterCardAlertMessage("Error: Transaction failed.")
                }

                return
            }

            print(result)

            if let paymentToken_ = paymentToken {// The orders are made with payment tokens so need to update the transaction
                DispatchQueue.main.async {
                  completionHandler(true)
                }
//                self.updateTransactionStatus(orderId: orderId, transactionId: transactionId, paymentToken: paymentToken_, completionHandler: completionHandler)
            } else { // The order is made whith 3d secure which is a initial payment for verification, no need to update the transaction
                DispatchQueue.main.async {
                    completionHandler(true)
                }
            }

            return
        }
    }

    func updateTransactionStatus(orderId: String, transactionId: String, paymentToken: String, completionHandler: @escaping ((_ success: Bool) -> Void)) {
        Utilities.showHUD(to: self.view, "")
        let requestParams: [String: Any] = [
            "orderId": orderId,
            "responseCode": "100",
            "transactionId": transactionId,
            "responseMessage": "SUCCESS",
            "token": paymentToken
            ] as [String: Any]

        ApiManager.shared.apiService.paymentUpdate2(requestParams as [String: AnyObject]).subscribe(onNext: { [weak self](updatedOrder) in

            Utilities.hideHUD(from: self?.view)
            debugPrint(updatedOrder)
            completionHandler(true)

            }, onError: { [weak self](error) in

                Utilities.hideHUD(from: self?.view)
                if let error_ = error as? ResponseError {
                    Utilities.showToastWithMessage(error_.description())
                }
                completionHandler(false)
        }).disposed(by: disposableBag)
    }

    func addMasterCardFlow(completionHandler: @escaping ((_ cards: [PaymentCard]) -> Void)) {
        let ccInputVC = UIStoryboard.init(name: "CheckOut", bundle: nil).instantiateViewController(withIdentifier: "CreditCardInputViewController") as! CreditCardInputViewController
        ccInputVC.didInputCCInfoHandler = { cardData in
            self.addNewCard(cardData: cardData, completionHandler: completionHandler)
        }
        self.present(ccInputVC, animated: true, completion: nil)
    }

    func addNewCard(cardData: [String: String], completionHandler: @escaping ((_ cards: [PaymentCard]) -> Void)) {
        Utilities.showHUD(to: self.view, "")
        self.merchantAPI.createSession { (result) in

            guard case .success(let response) = result,
                "SUCCESS" == response[at: "gatewayResponse.result"] as? String,
                let sessionId = response[at: "gatewayResponse.session.id"] as? String,
                let apiVersion = response[at: "apiVersion"] as? String else {
                    // if anything was missing, flag the step as having errored
                    print("Error Creating Session")

                    DispatchQueue.main.async {
                        Utilities.hideHUD(from: self.view)
                        Utilities.showMasterCardAlertMessage("Error Creating Session")
                    }

                    return
            }

            var request = GatewayMap()

            request[at: "sourceOfFunds.provided.card.nameOnCard"] = cardData["name"]
            request[at: "sourceOfFunds.provided.card.number"] = cardData["number"]
            request[at: "sourceOfFunds.provided.card.securityCode"] = cardData["cvv"]
            request[at: "sourceOfFunds.provided.card.expiry.month"] = cardData["month"]
            request[at: "sourceOfFunds.provided.card.expiry.year"] = cardData["year"]

            /*request[at: "sourceOfFunds.provided.card.nameOnCard"] = "Test Name"
            request[at: "sourceOfFunds.provided.card.number"] = "4111111111111111"
            request[at: "sourceOfFunds.provided.card.securityCode"] = "222"
            request[at: "sourceOfFunds.provided.card.expiry.month"] = "12"
            request[at: "sourceOfFunds.provided.card.expiry.year"] = "22"*/

            self.gateway.updateSession(sessionId, apiVersion: apiVersion, payload: request) {
                (result) in
                guard case .success(let response) = result,
                    let sessionId = response[at: "session"] as? String else {
                        // if anything was missing, flag the step as having errored
                        print("Error Creating Session")

                        DispatchQueue.main.async {
                            Utilities.hideHUD(from: self.view)
                            Utilities.showMasterCardAlertMessage("Error Creating Session")
                        }

                        return
                }
                self.merchantAPI.executeCheck3DSEnrollment(sessionId: sessionId, amount: self.threeDScheckAmount) { result in
                    guard case .success(let response) = result, let recommendation = response[at: "gatewayResponse.3dsEnrollment.gatewayRecommendation"] as? String else {
                        print("Error checking 3DS Enrollment")
                        DispatchQueue.main.async {
                            Utilities.hideHUD(from: self.view)
                            Utilities.showMasterCardAlertMessage("Error checking 3DS Enrollment")
                        }

                        return
                    }

                    if recommendation == "DO_NOT_PROCEED" {
                        print("3DS Do Not Proceed")
                    }

                    // if PROCEED in recommendation, and we have HTML for 3ds, perform 3DS
                    if let html = response[at: "gatewayResponse.3dsEnrollment.htmlBodyContent"] as? String {
                        let threeDSecureId = response[at: "gatewayResponse.3dsEnrollment.secureId"] as? String
                        self.begin3DSAuth(simple: html, sessionId: sessionId, threeDSecureId: threeDSecureId, completionHandler: completionHandler)
                    } else { // No 3ds necessary, save card directly
                       self.saveNewCard(sessionId: sessionId, completionHandler: completionHandler)
                    }
                }
            }

            print(result)
            return
        }
    }

    fileprivate func begin3DSAuth(simple: String, sessionId: String?, threeDSecureId: String?, completionHandler: @escaping ((_ cards: [PaymentCard]) -> Void)) {
        // instatniate the Gateway 3DSecureViewController and present it
       
        var threeDSecureView: Gateway3DSecureViewController?

        DispatchQueue.main.async {
            Utilities.hideHUD(from: self.view)
            threeDSecureView = Gateway3DSecureViewController(nibName: nil, bundle: nil)

            self.present(threeDSecureView!, animated: true)

            // Optionally customize the presentation
            threeDSecureView!.title = "3-D Secure Auth"
            //        threeDSecureView.navBar.tintColor = brandColor

            // Start 3D Secure authentication by providing the view with the HTML content provided by the check enrollment step
            //        threeDSecureView.authenticatePayer(htmlBodyContent: simple, handler: handle3DS(authView:result:))

            threeDSecureView!.authenticatePayer(htmlBodyContent: simple, handler: {
                (authView: Gateway3DSecureViewController, result: Gateway3DSecureResult) in
                self.handle3DS(sessionId: sessionId, threeDSecureId: threeDSecureId, authView: authView, result: result, completionHandler: completionHandler)
            })
        }


    }

    func handle3DS(sessionId: String?, threeDSecureId: String?, authView: Gateway3DSecureViewController, result: Gateway3DSecureResult, completionHandler: @escaping ((_ cards: [PaymentCard]) -> Void)) {
        // dismiss the 3DSecureViewController
        authView.dismiss(animated: true, completion: {
            switch result {
            case .error(_):
                print("3DS Authentication Failed")
                Utilities.showMasterCardAlertMessage("3DS Authentication Failed")

            case .completed(gatewayResult: let response):
                // check for version 46 and earlier api authentication failures and then version 47+ failures
                if let status = response[at: "response.gatewayRecommendation"] as? String, status == "DO_NOT_PROCEED"  {
                    print("3DS Authentication Failed")
                    Utilities.showMasterCardAlertMessage("3DS Authentication Failed")
                } else {

                    self.processPayment3DS(sessionId:sessionId, threeDSecureId: threeDSecureId, completionHandler: completionHandler)

                    Utilities.showHUD(to: self.view, "Processing payment")

                }
            default:
                print("3DS Authentication Cancelled")
                Utilities.showMasterCardAlertMessage("3DS Authentication Cancelled")
            }
        })
    }

    func processPayment3DS(sessionId: String?, threeDSecureId: String?, completionHandler: @escaping ((_ cards: [PaymentCard]) -> Void)) {
        let transactionId = "trans-\(Transaction.randomID())"
        let orderId = "order-\(Transaction.randomID())"
        self.makePayment(paymentToken: nil, sessionId: sessionId, threeDSecureId: threeDSecureId, orderId: orderId, transactionId:transactionId, amount: threeDScheckAmount, currency:"BHD") { (success) in
            if true == success {
                self.saveNewCard(sessionId: sessionId ?? "", completionHandler: completionHandler)
            } else {
                Utilities.showToastWithMessage("Payment error, can not add card")
            }
        }
    }

    func saveNewCard(sessionId: String, completionHandler: @escaping ((_ cards: [PaymentCard]) -> Void)) {
        let requestParams: [String: Any] = [
            "userId": Utilities.shared.user?.id ?? 0,
            "sessionId": sessionId] as [String: Any]
        ApiManager.shared.apiService.saveCard(requestParams as [String: AnyObject]).subscribe(onNext: { [weak self](savedCards) in

            Utilities.hideHUD(from: self?.view)
            debugPrint(savedCards)

            completionHandler(savedCards)

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
                /*if let acompletionHandler = completionHandler {
                 acompletionHandler(false)
                 }*/
        }).disposed(by: disposableBag)
    }


    func prepareTransaction(isBenefitPay: Bool? = false, tokenString: String, tokenizedCustomerEmail: String, customerPassword: String, order_: Order? = nil, grandTotal: Float? = 0.300, completionHandler: ((_ isCardSaved: Bool) -> Void)? = nil) {
        
//        let waselDeliveryKeys = WaselDeliveryKeys()
        var merchantEmail_ = ""//waselDeliveryKeys.creditCardMerchantEmail
        var secretKey_ = ""//waselDeliveryKeys.creditCardSecretKey
        
//        if let isBenefitPay_ = isBenefitPay, true == isBenefitPay_ {
//            merchantEmail_ = waselDeliveryKeys.benefitMerchantEmail
//            secretKey_ = waselDeliveryKeys.benefitSecretKey
//        }
        
        var productNames_ = ""
        if let items = order_?.items {
            _ = items.map ({ (item) -> String? in
                if let name_ = item.name, false == name_.isEmpty {
                    if false == productNames_.isEmpty {
                        productNames_.append("|")
                    }
                    productNames_.append(name_)
                    return name_
                }
                return nil
            })
        }

        let total_ = grandTotal ?? 0.300 //0.300 for BHD
        let dict = ["merchant_email": merchantEmail_,
                    "secret_key": secretKey_,
                    "currency": "BHD",
                    "amount": total_,
                    "title": "WaselDelivery",
                    "phone_number": Utilities.getUser()?.mobile ?? "",
                    "order_id": String(order_?.id ?? 0),
                    "product_name": (true == productNames_.isEmpty) ? "Adding Card" : productNames_,
                    "customer_email": tokenizedCustomerEmail,
                    "country_billing": "BHR",
                    "address_billing": "Manama Bahrain",
                    "city_billing": "Manama",
                    "state_billing": "Manama",
                    "postal_code_billing": "00973",
                    "pt_token": tokenString,
                    "pt_customer_email": tokenizedCustomerEmail,
                    "pt_customer_password": customerPassword] as [String: Any]
        
        guard let url_ = URL(string: "https://www.paytabs.com/apiv3/tokenized_transaction_prepare") else {
            if let acompletionHandler = completionHandler {
                acompletionHandler(false)
            }
            return
        }
        Utilities.showHUD(to: self.view, "")
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
                    acompletionHandler(false)
                }
                return
            }
            
            do {
                DispatchQueue.main.async {
                    Utilities.hideHUD(from: self.view)
                }

                guard var jsonString = String(data: data ?? Data(), encoding: .utf8) else {
                    if let acompletionHandler = completionHandler {
                        acompletionHandler(false)
                    }
                    return
                }
                jsonString = jsonString.replacingOccurrences(of: "null", with: "")
                
                let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8) ?? Data(), options: .mutableContainers) as? NSDictionary

                if let parseJSON = json {
                    if let resultValue: String = parseJSON["result"] as? String {
                        debugPrint("result: \(resultValue)")
                        
                        let responseCode_: Int = parseJSON["response_code"] as? Int ?? 0
                        let transactionId_: Int = parseJSON["transaction_id"] as? Int ?? 0
                        
                        if 0 < transactionId_ {
                            let orderId_ = order_?.id ?? 0
                            if 0 < orderId_ {
                                self.updateTransactionStatus(tokenString: tokenString, tokenizedCustomerEmail: tokenizedCustomerEmail, customerPassword: customerPassword, transactionId: String(transactionId_), responseCode: responseCode_, order_: order_, completionHandler: { (isPaymentUpdated) in
                                    if true == isPaymentUpdated {
                                        if let acompletionHandler = completionHandler {
                                            acompletionHandler(true)
                                        }
                                        return
                                    } else {
                                        if let acompletionHandler = completionHandler {
                                            acompletionHandler(false)
                                        }
                                        return
                                    }
                                })
                            } else {
                                if let acompletionHandler = completionHandler {
                                    acompletionHandler(true)
                                }
                            }
                        } else {
                            let message_: String = resultValue
                            Utilities.showToastWithMessage(message_, position: .middle)
                            if let acompletionHandler = completionHandler {
                                acompletionHandler(false)
                            }
                        }
                    } else {
                        let message_: String = parseJSON["message"] as? String ?? "Something went wrong."
                        Utilities.showToastWithMessage(message_, position: .middle)
                        if let acompletionHandler = completionHandler {
                            acompletionHandler(false)
                        }
                    }
                } else {
                    if let acompletionHandler = completionHandler {
                        acompletionHandler(false)
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
                    acompletionHandler(false)
                }
            }
        }
        task.resume()
    }
    
    func updateTransactionStatus(isBenefitPay: Bool? = false, tokenString: String, tokenizedCustomerEmail: String, customerPassword: String, transactionId: String, responseCode: Int, order_: Order? = nil, completionHandler: ((_ isCardSaved: Bool) -> Void)? = nil) {
        Utilities.showHUD(to: self.view, "")
        
        let key = publicKey
        let iv = publicKey
        let content = tokenString
        var encodedTokenString = ""
        do {
            encodedTokenString =  try content.aesEncrypt(key: key, iv: iv)
        } catch {
            encodedTokenString = ""
        }
        debugPrint(encodedTokenString)
        
        var encodedPasswordString = ""
        do {
            encodedPasswordString =  try customerPassword.aesEncrypt(key: key, iv: iv)
        } catch {
            encodedPasswordString = ""
        }
        debugPrint(encodedPasswordString)

        let requestParams: [String: Any] = ["customerEmail": tokenizedCustomerEmail, "customerPassword": encodedPasswordString, "isDefault": true, "orderId": order_?.id ?? 0, "responseCode": responseCode, "token": encodedTokenString, "transactionId": transactionId] as [String: Any]
        
        disposeObj = ApiManager.shared.apiService.paymentUpdate(requestParams as [String: AnyObject]).subscribe(
            onNext: { [weak self](order) in
                Utilities.hideHUD(from: self?.view)
                if let order_ = order as? Order {
                    debugPrint(order_)
                    if order_.responseCode != "100" { //Status code is 100. If not sucessed show the toast else show the success view
                        Utilities.showToastWithMessage(order_.txnResponseMessage ?? "Something went wrong.", position: .middle)
                        if let acompletionHandler = completionHandler {
                            acompletionHandler(false)
                        }
                        return
                    }
                    if let acompletionHandler = completionHandler {
                        acompletionHandler(true)
                    }
                }
            }, onError: { [weak self](error) in
                Utilities.hideHUD(from: self?.view)
                if let error_ = error as? ResponseError {
                    if error_.getStatusCodeFromError() == .accessTokenExpire {
                        
                    } else {
                        Utilities.showToastWithMessage(error_.description())
                    }
                }
                if let acompletionHandler = completionHandler {
                    acompletionHandler(false)
                }
        })
        disposeObj?.disposed(by: disposableBag)
    }
    
//    func testAES() {
//        let key = publicKey
//        let iv = publicKey
//        let content = "bhavani@gmail.comm"
//        let encodedString = try! content.aesEncrypt(key: key, iv: iv)
//        debugPrint(encodedString)
//        let deCodedString = try! encodedString.aesDecrypt(key: key, iv: iv)
//        debugPrint(deCodedString)
//    }
    
// MARK: Close SDK Event
    
    private func handleBackButtonTapEvent() {
//        self.initialSetupViewController.willMove(toParent: self)
//        self.initialSetupViewController.view.removeFromSuperview()
//        self.initialSetupViewController.removeFromParent()
    }
    
    private func saveCard(customerEmail: String, customerPassword: String, isDefaultCard: Bool, token: String, transactionId: String, completionHandler: ((_ isCardSaved: Bool) -> Void)? = nil) {
        
        guard Utilities.shared.isNetworkReachable() else {
            showNoInternetMessage()
            return
        }
        
        let key = publicKey
        let iv = publicKey
        let content = token
        var encodedTokenString = ""
        do {
            encodedTokenString =  try content.aesEncrypt(key: key, iv: iv)
        } catch {
            encodedTokenString = ""
        }
        debugPrint(encodedTokenString)
        
        var encodedPasswordString = ""
        do {
            encodedPasswordString =  try customerPassword.aesEncrypt(key: key, iv: iv)
        } catch {
            encodedPasswordString = ""
        }
        debugPrint(encodedPasswordString)
        
        let user = Utilities.getUser()
        let userId_ = Int(user?.id ?? "-1") ?? -1
        let requestParams: [String: Any] = ["customerEmail": customerEmail, "customerPassword": encodedPasswordString, "default": isDefaultCard, "token": encodedTokenString, "transactionId": transactionId, "userId": userId_] as [String: Any]
        Utilities.showHUD(to: self.view, "")
        disposeObj = ApiManager.shared.apiService.saveCard(requestParams as [String: AnyObject]).subscribe(onNext: { [weak self](savedCards) in
            
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
