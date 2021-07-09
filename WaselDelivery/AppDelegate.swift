//
//  AppDelegate.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 13/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import GoogleSignIn
import FBSDKCoreKit
import GoogleMaps
import UserNotifications
import Log
import Foundation
import Toaster
import BugfenderSDK
import RxSwift
import Upshot
import IQKeyboardManagerSwift

struct Platform {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    enum QuickAction: String {
        case outlets
        case search
        case orderAnything
        case orderHistory

        init?(fullType: String) {
            guard let shortId = fullType.components(separatedBy: ".").last else { return nil }
            self.init(rawValue: shortId)
        }
    }

    var window: UIWindow?
    var deviceToken: String?
    let log = Logger()
    private let sharedUtilities = Utilities.shared
    fileprivate var disposableBag = DisposeBag()
//    var isForceUpdateAlertDisplayed : Bool = false
    fileprivate var isUpshotWindowVisible: Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        UPSHOTActivitySetup.shared.initialiseUPSHOT()
        UPSHOTActivitySetup.shared.showUPSHOTActivities(activityTag: "Splash")
        self.keyWindows()

//        BFLog("", tag: "AppStatus-Launch", level: .default)
        application.applicationIconBadgeNumber = 0
        ApiManager.shared.apiServiceType = .apiService
        NotificationCenter.default.addObserver(self, selector: #selector(callAppSettingsAPI), name: NetworkStatusChangeNotification, object: nil)
        
        checkPushNotificationsPermission { (isPushNotificationEnabled) in
            debugPrint(isPushNotificationEnabled)
            let userInfo = BKUserInfo.init()
            let infoDict = ["NotificationStatus": (true == isPushNotificationEnabled) ? "Enable" : "Disable"]
            userInfo.others = infoDict
            userInfo.build(completionBlock: nil)
        }

        // Call Version API
        if Platform.isSimulator == false {
            registerForPushNotifications(application: application)
            if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject],
                let bodyString = notification["body"] as? String,
                let bodyDict = Utilities.convertTextToDictionary(text: bodyString),
                let orderDict = bodyDict["order"] as? [String: AnyObject],
                let notificationId_ = orderDict["id"] as? Int,
                1 ... 10 ~= notificationId_ {
                    self.showOrderDetailNotification(aDict_: orderDict)
            }
            // HockeyIntegration//WaselCerti--af27c0ba61884144b9a3313eddd6821d///PTCerti--45ed16bce6884f7392e5bea8d5e79632
//            BITHockeyManager.shared().configure(withIdentifier: "af27c0ba61884144b9a3313eddd6821d")
//            BITHockeyManager.shared().isUpdateManagerDisabled = true
//            BITHockeyManager.shared().start()
//            BITHockeyManager.shared().authenticator.authenticateInstallation()
//            BITHockeyManager.shared().crashManager.crashManagerStatus = .autoSend
        }
        
        #if DEBUG
            log.enabled = true
        #else
            log.enabled = false
        #endif
    
        // Facebook Setup
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        GMSServices.provideAPIKey(GoogleAPIKey)

        sharedUtilities.setupReachability()
        ToastView.appearance().font = UIFont.montserratRegularWithSize(14)
        
        if #available(iOS 9.0, *) {
            if let shortcutItem =
                launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem]
                    as? UIApplicationShortcutItem {
                
                return handleQuickAction(shortcutItem: shortcutItem)
            }
        }
        // BugFender
        Bugfender.activateLogger("MWYmc1OIYyj7Na0AfniXRCDZyWn3r5wO")
        
        IQKeyboardManager.shared.enable = true
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        self.callAppSettingsAPI()
        
        // Uncomment the below code to send the push notification status to the server
//        checkPushNotificationsPermission { (isPushNotificationEnabled) in
//            debugPrint(isPushNotificationEnabled)
//        }
    }

    func checkPushNotificationsPermission(completionHandler: @escaping ((_ isPushNotificationEnabled: Bool) -> Void)) {
        if #available(iOS 10.0, *) {
            let current = UNUserNotificationCenter.current()
            current.getNotificationSettings(completionHandler: { (settings) in
                
                if settings.authorizationStatus == .authorized {
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            })
        } else {
            if let status = UIApplication.shared.currentUserNotificationSettings?.types {
                let status = status.rawValue != UIUserNotificationType(rawValue: 0).rawValue
                completionHandler(status)
            } else {
                completionHandler(false)
            }
        }
    }

    func registerForPushNotifications(application: UIApplication) {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, _) in
                if granted == true {
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                }
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
//        BFLog("", tag: "AppStatus-Foreground", level: .default)
        UPSHOTActivitySetup.shared.initialiseUPSHOT()
        checkPushNotificationsPermission { (isPushNotificationEnabled) in
            debugPrint(isPushNotificationEnabled)
            let userInfo = BKUserInfo.init()
            let infoDict = ["NotificationStatus": (true == isPushNotificationEnabled) ? "Enable" : "Disable"]
            userInfo.others = infoDict
            userInfo.build(completionBlock: nil)
        }
        
        getPendingFeedbackOrders()
        refreshOrderScreen(aDict: nil)
        if Utilities.shouldUseCurrentLocation() == true {
            sharedUtilities.enteredForeground = true
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: UpdateCurrentLocationNotification), object: nil)            
        }
        self.fetchAppVersion(isFromBackground: true)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
//        BFLog("", tag: "AppStatus-InActive", level: .default)
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        NotificationCenter.default.removeObserver(self, name: NetworkStatusChangeNotification, object: nil)
    }
    
    func application(_ application: UIApplication, didChangeStatusBarFrame oldStatusBarFrame: CGRect) {
        if let cartView_ = Utilities.shared.cartView {
            let statusBarFrame: CGRect = UIApplication.shared.statusBarFrame
            let topPosition = (60.0 + (20.0 >= statusBarFrame.size.height ? 0.0 : (statusBarFrame.size.height - 20.0)))
            cartView_.frame = CGRect(x: 0.0, y: ScreenHeight - topPosition, width: ScreenWidth, height: 60.0)
        }
        Utilities.showTransparentView()
        NotificationCenter.default.post(name: Notification.Name(rawValue: OrderDetailsTableViewHeightNotification), object: nil, userInfo: nil)
    }

    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return self.handleOpenUrl(url, forApplication: app, withSource: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, andAnnotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }
     
    func application(_ application: UIApplication,
                     open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return self.handleOpenUrl(url, forApplication: application, withSource: sourceApplication, andAnnotation: annotation)
    }
    
    func handleOpenUrl(_ url: URL, forApplication app: UIApplication, withSource source: String?, andAnnotation annotation: Any?) -> Bool {
        let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
        if let filePath_ = filePath,
            let dict = NSDictionary(contentsOfFile: filePath_) as? [String: AnyObject],
            url.scheme == dict["REVERSED_CLIENT_ID"] as? String {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication: source,
                                                     annotation: annotation)
        }
        
        let infoDict = Bundle.main.infoDictionary
        if let infoDict_ = infoDict,
            let fbId = infoDict_["FacebookAppID"] as? String,
            url.scheme == "fb\(fbId)" {
            return ApplicationDelegate.shared.application(app, open: url, sourceApplication: source, annotation: annotation)
        }
        return false
    }
    
// MARK: - Notification delegates
       
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        BFLog("Error %@", error as CVarArg , tag: "Notifications-FailToRegister", level: .default)
        Utilities.log(error as AnyObject, type: .error)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        self.deviceToken = deviceTokenString
//        BFLog("DeviceToken %@", deviceToken as CVarArg, tag: "Notifications-didRegister", level: .default)
        Utilities.log(self.deviceToken as AnyObject, type: .info)
        updateDeviceToken()
        UPSHOTActivitySetup.shared.sendDeviceTokenToUpshot(deviceToken: deviceTokenString)
    }
    
    @nonobjc @available(iOS 10.0, *)
    private func userNotificationCenter(center: UNUserNotificationCenter, didReceiveNotificationResponse response: UNNotificationResponse, withCompletionHandler completionHandler: () -> Void) {
        // Handle the notification
        let userInfo = response.notification.request.content.userInfo
        self.handlePushNotification(userInfo: userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Swift.Void) {
        self.handlePushNotification(userInfo: userInfo)
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Called to let your app know which action was selected by the user for a given notification.
        self.handlePushNotification(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let appData = userInfo["appData"] as? [String: Any],
            let deepLink = appData["deepLink"] as? String {
            print("DeepLink:", deepLink)
            completionHandler([.alert, .sound])
        } else {
            handlePushNotification(userInfo: userInfo)
            completionHandler([])
        }
    }
    
    func handleDeepLinkNotification(userInfo: [AnyHashable: Any]) {
        NSLog("handleDeepLinkNotification:%@", userInfo)
        let application = UIApplication.shared
        application.applicationIconBadgeNumber = 0
        if let bodyString = userInfo["body"] as? String,
            let bodyDict_ = Utilities.convertTextToDictionary(text: bodyString),
            let notificationId_ = bodyDict_["id"] as? Int, 1 ... 10 ~= notificationId_ {
            if application.applicationState == .inactive || application.applicationState == .background {
                showOrderDetailNotification(aDict_: bodyDict_ as [String: AnyObject])
            } else { //app is in forground
                refreshOrderScreen(aDict: bodyDict_)
            }
        } else {
            // Handle upshot deep link actions
            handleUpshotDeepLinkAction(userData: userInfo)
        }
    }
    
    func handleUpshotDeepLinkAction (userData data: [AnyHashable: Any]) {
        if Utilities.shared.cart.cartItems.count > 0 {
            if let navVC = window?.rootViewController as? UINavigationController {
                if let tabVC = navVC.viewControllers.first as? UITabBarController {
                    if let aViewController = tabVC.presentedViewController {
                        if let nVC = aViewController as? UINavigationController {
                            if let aVc = nVC.viewControllers.last {
                                if let className = NSStringFromClass(aVc.classForCoder).components(separatedBy: ".").last {
                                    if className == "PopupViewController" {
                                        DispatchQueue.main.async {
                                            aVc.dismiss(animated: false, completion: {
                                                self.showClearCartPopUpOnViewController(visibleController: aVc, userData: data)
                                                return
                                            })
                                        }
                                    }
                                    if className == "ConfirmOrderController" || className == "PopupViewController" || className == "CardPaymentViewController" || className == "CartViewController" {
                                        self.showClearCartPopUpOnViewController(visibleController: aVc, userData: data)
                                        return
                                    }
                                }
                            }
                        }
                    }
                }
                
                self.showClearCartPopUpOnViewController(visibleController: navVC, userData: data)
            }
        } else {
            self.navigateDeepLinkActionScreenBasedOn(userData: data)
        }
    }
    
    func showClearCartPopUpOnViewController(visibleController: UIViewController, userData data: [AnyHashable: Any]) {
        let popupVC = PopupViewController()
        let responder = popupVC.showAlert(viewcontroller: visibleController, title: "Wasel Delivery", text: "You can only order from one place. When you leave this place your cart will be cleared.", buttonText: "Cancel", cancelButtonText: "Clear")
        responder.addCancelAction({
            DispatchQueue.main.async(execute: {
                Utilities.shared.clearCart()
                Utilities.shared.currentOutlet = nil
                self.navigateDeepLinkActionScreenBasedOn(userData: data)
            })
        })
    }
    
    func navigateDeepLinkActionScreenBasedOn(userData data: [AnyHashable: Any]) {
        guard let appData = data["appData"] as? [String: Any] else {
            return
        }

        func openDeepLink(deepLink: String) {
            let deepLink = deepLink
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let navVC = self.window?.rootViewController as? UINavigationController
                if navVC?.viewControllers.first as? UITabBarController != nil {
                    self.handlingDeepLink(deepLinkString: deepLink)
                } else {
                    openDeepLink(deepLink: deepLink)
                }
            }
        }

        if let deepLinkString = appData["deepLink"] as? String {
            NSLog("deepLinkString:%@", deepLinkString)
            openDeepLink(deepLink: deepLinkString)
        }
    }

    func handlingDeepLink(deepLinkString: String) {
        // Navigating to first screen of each module like home/search/orderanything/history/profile
        let navVC = window?.rootViewController as? UINavigationController
        if let tabVC = navVC?.viewControllers.first as? UITabBarController {
            if let viewControllers = tabVC.viewControllers {
                for aViewController in viewControllers {
                    if let navVC = aViewController as? UINavigationController {
                        navVC.popToRootViewController(animated: false)
                    }
                }
            }
            
            if let aViewController = tabVC.presentedViewController {
                aViewController.dismiss(animated: false, completion: nil)
            }
        }

        var categoryId = ""
        var storeId = ""
        var productId = ""
        var isOrderAnythingDeepLink = false

        if let components = URLComponents(string: deepLinkString) {
            if let queryItems = components.queryItems {
                for item in queryItems {
                    if let itemValue = item.value {
                        if item.name == "CategoryId" {
                            categoryId = itemValue
                        } else if item.name == "StoreId" {
                            storeId = itemValue
                        } else if item.name == "ProductId" {
                            productId = itemValue
                        } else if item.name == "OrderAnything" {
                            if let isOrderAnythingDeepLink_ = Bool(itemValue) {
                                isOrderAnythingDeepLink = isOrderAnythingDeepLink_
                            }
                        }
                    }
                }
                if false == categoryId.isEmpty, false == storeId.isEmpty, false == productId.isEmpty {
                    // Navigating to outlet details(Store) and add the item to cart
                    if let tabVC = navVC?.viewControllers.first as? UITabBarController {
                        tabVC.selectedIndex = 0
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: DeepLinkCategoryNotification), object: categoryId)
                        let storyBoard = Utilities.getStoryBoard(forName: .main)
                        guard let controller = storyBoard.instantiateViewController(withIdentifier: "OutletDetailsViewController") as? OutletDetailsViewController else {
                            return
                        }

                        controller.loadRestaurantDetails(isRepeatOrder: false, getHeaderDetails: true, storeId: storeId, completionHandler: { (isOutletHeaderDetailsFetched, _) in

                            guard isOutletHeaderDetailsFetched else { return }
                            controller.loadRestaurantDetails(isRepeatOrder: false, getHeaderDetails: false, storeId: storeId, completionHandler: { (isProductListFetched, _) in

                                guard isProductListFetched else { return }
                                Utilities.shouldHideTabCenterView(tabVC, true)

                                controller.isFromSearchScreen = false
                                controller.isFromDeeplink = true
                                controller.productId = productId
                                let navController_ = tabVC.viewControllers?[0] as? UINavigationController
                                navController_?.pushViewController(controller, animated: true)
                            })
                        })
                    }
                } else if false == categoryId.isEmpty && true == storeId.isEmpty {
                    // Switching to main category(Food,Cars,Sports,etc)
                    if let tabVC = navVC?.viewControllers.first as? UITabBarController {
                        tabVC.selectedIndex = 0
                        Utilities.shouldHideTabCenterView(tabVC, false)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: DeepLinkCategoryNotification), object: categoryId)
                    }
                } else if false == storeId.isEmpty && false == categoryId.isEmpty {
                    // Navigating to outlet details(Store)
                    if let tabVC = navVC?.viewControllers.first as? UITabBarController {
                        tabVC.selectedIndex = 0
                        Utilities.shouldHideTabCenterView(tabVC, true)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: DeepLinkCategoryNotification), object: categoryId)
                        let storyBoard = Utilities.getStoryBoard(forName: .main)
                        guard let controller = storyBoard.instantiateViewController(withIdentifier: "OutletDetailsViewController") as? OutletDetailsViewController else {
                            return
                        }
                        
                        controller.loadRestaurantDetails(isRepeatOrder: false, getHeaderDetails: true, storeId: storeId, completionHandler: { (isOutletHeaderDetailsFetched, _) in

                            guard isOutletHeaderDetailsFetched else { return }
                            controller.loadRestaurantDetails(isRepeatOrder: false, getHeaderDetails: false, storeId: storeId, completionHandler: { (isOutletDetailsFetched, outlet_) in
                                if true == isOutletDetailsFetched {
                                    controller.isFromSearchScreen = false
                                    if true == outlet_?.showVendorMenu {
                                        controller.outlet = outlet_
                                        let navController_ = tabVC.viewControllers?[0] as? UINavigationController
                                        navController_?.pushViewController(controller, animated: true)
                                    } else {
                                        let controller = OrderAnythingController.instantiateFromStoryBoard(.main)
                                        controller.outlet = outlet_
                                        controller.isVendorOutLet = true
                                        controller.isFromSearchScreen = false
                                        controller.hidesBottomBarWhenPushed = true
                                        let navController_ = tabVC.viewControllers?[0] as? UINavigationController
                                        navController_?.pushViewController(controller, animated: true)
                                        Utilities.shouldHideTabCenterView(tabVC, true)
                                    }
                                }
                            })
                        })
                    }
                } else if true == isOrderAnythingDeepLink {
                    // Navigating to order anything screen(Needs to add conditions for checkout flow)
                    if let tabVC = navVC?.viewControllers.first as? UITabBarController {
                        tabVC.selectedIndex = 2
                        Utilities.shouldHideTabCenterView(tabVC, false)
                    }
                } else {
                    // Navigating to Home screen
                    if let tabVC = navVC?.viewControllers.first as? UITabBarController {
                        tabVC.selectedIndex = 0
                        Utilities.shouldHideTabCenterView(tabVC, false)
                    }
                }
            }
        }
    }
    
    func handlePushNotification(userInfo: [AnyHashable: Any]) {
        //        BFLog("", tag: "Notifications-ReceivedNotification", level: .default)
        Utilities.log(userInfo["aps"] as AnyObject? ?? "" as AnyObject, type: .info)
        UPSHOTActivitySetup.shared.showPushNotification(userInfo: userInfo)
        let application = UIApplication.shared
        application.applicationIconBadgeNumber = 0
        if let bodyString = userInfo["body"] as? String,
            let bodyDict_ = Utilities.convertTextToDictionary(text: bodyString),
            let notificationId_ = bodyDict_["id"] as? Int, 1 ... 10 ~= notificationId_ {
            if application.applicationState == .inactive || application.applicationState == .background {
                showOrderDetailNotification(aDict_: bodyDict_ as [String: AnyObject])
            } else { //app is in foreground
                refreshOrderScreen(aDict: bodyDict_)
            }
        }
            // Uncomment the below code for upshot deep link featue
        else {
            handleDeepLinkNotification(userInfo: userInfo)
        }
    }
    
    // 3D Touch support
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleQuickAction(shortcutItem: shortcutItem))
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
//        BFLog("", tag: "AppStatus-Background", level: .default)
        Hud.shared.hideHUD()
        sharedUtilities.cancelTimer()
        BrandKinesis.sharedInstance().terminate()
    }
    
    @available(iOS 9.0, *)
    func handleQuickAction(shortcutItem: UIApplicationShortcutItem) -> Bool {
        let fullId = shortcutItem.type
        let shortId = QuickAction.init(fullType: fullId)
        
        // Better way to do this is to check if the user is logged in
        // If he is logged in, then show 3 3DTouch options
        // Otherwise, probably only 1, say Login?
        let navVC = window?.rootViewController as? UINavigationController
        let tabVC = navVC?.viewControllers.first as? UITabBarController
        if let v = tabVC {
            debugPrint("Root view controller: \(v)")
        }
        if let s = shortId {
            switch s {
            case .outlets:
                tabVC?.selectedIndex = 0
            case .search:
                tabVC?.selectedIndex = 1
            case .orderAnything:
                tabVC?.selectedIndex = 2
            case .orderHistory:
                tabVC?.selectedIndex = 3
            }
            return true
        } else {
            return false
        }
    }
    
// MARK: - Support Methods
    
    func updateDeviceToken() {
        
        guard sharedUtilities.isNetworkReachable() else {
            return
        }
        guard let user_ = sharedUtilities.user, let id_ = user_.id else {
            self.updateDeviceTokenWithOutLogin()
            return
        }
        guard let deviceToken_ = deviceToken else {
            return
        }
        let deviceObject: [String: AnyObject] = [ UserIdKey: id_ as AnyObject,
                                                  IsAndroidKey: false as AnyObject,
                                                  DeviceTokenKey: deviceToken_ as AnyObject]
        
        ApiManager.shared.apiService.updateDeviceToken(deviceObject as [String: AnyObject]).subscribe(
            onNext: { (_) in
//                Utilities.showToastWithMessage("device token update: \(self.deviceToken)")
        }, onError: { (error) in
            if let error_ = error as? ResponseError {
                if error_.getStatusCodeFromError() == .accessTokenExpire {
                } else {
                    Utilities.showToastWithMessage(error_.description())
                }
            }
        }).dispose()
    }
    
    func updateDeviceTokenWithOutLogin() {
        guard sharedUtilities.isNetworkReachable() else {
            return
        }

        guard let deviceToken_ = deviceToken else {
            return
        }

        let deviceObject: [String: AnyObject] = [ IsAndroidKey: false as AnyObject,
                                                  DeviceTokenKey: deviceToken_ as AnyObject]
        
        ApiManager.shared.apiService.updateDeviceTokenWithOutLogin(deviceObject as [String: AnyObject]).subscribe(
            onNext: { (_) in
                //                Utilities.showToastWithMessage("device token update: \(self.deviceToken)")
        }, onError: { (error) in
            if let error_ = error as? ResponseError {
                if error_.getStatusCodeFromError() == .accessTokenExpire {
                } else {
                    Utilities.showToastWithMessage(error_.description())
                }
            }
        }).dispose()
    }
    
    func showForceUpdateAlert() {
        if let rootController = self.window?.rootViewController {
            let alertViewController = UIAlertController(title: "", message: "There is a new version available. Please update.", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .default) { (_) -> Void in
                if let appStoreUrl = URL(string: "https://itunes.apple.com/us/app/wasel-delivery/id1255782431?mt=8") {
                    UIApplication.shared.open(appStoreUrl, options: [:], completionHandler: nil)
                }
            }
            alertViewController.addAction(okAction)
            rootController.present(alertViewController, animated: true, completion: nil)
        }
    }
    
    func fetchAppVersion(isFromBackground: Bool? = false) {
        guard Utilities.shared.isNetworkReachable() else {
            if false == isFromBackground {
                Utilities.showToastWithMessage("Looks like you are offline, please check internet connectivity.")
            }
            return
        }
        if let rootControllerView = self.window?.rootViewController?.view {
            _ = ApiManager.shared.apiService.fetchAppVersion("ios").subscribe(onNext: { [weak self](appVersion) in
                Utilities.hideHUD(from: rootControllerView)
                
                if let isForceUpdateAvailable = appVersion.forceUpdate, true == isForceUpdateAvailable {
                    if let appVersion = appVersion.version, false == appVersion.isEmpty {
                        if let infoDictionary = Bundle.main.infoDictionary {
                            if let currentVersion = infoDictionary["CFBundleShortVersionString"] as? String {
                                if (appVersion as NSString).compare(currentVersion) == .orderedDescending {
                                    self?.showForceUpdateAlert()
                                } else if false == isFromBackground {
                                    self?.setUp()
                                }
                            }
                        }
                    } else if false == isFromBackground {
                        self?.setUp()
                    }
                } else if false == isFromBackground {
                    self?.setUp()
                }
                }, onError: { [weak self](error) in
                    Utilities.hideHUD(from: rootControllerView)
                    if false == isFromBackground {
                        self?.setUp()
                    }
                    if let error_ = error as? ResponseError {
                        if error_.getStatusCodeFromError() == .accessTokenExpire {
                            
                        } else {
                            Utilities.showToastWithMessage(error_.description())
                        }
                    }
            }).disposed(by: disposableBag)
        }
    }

    func setUp() {
        var timeInterval = 0
        if isUpshotWindowVisible {
            timeInterval = 2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(timeInterval)) {
            BrandKinesis.sharedInstance().removeTutorials()
            self.isUpshotWindowVisible = false
            
            if let user_ = Utilities.getUser() {
                self.sharedUtilities.user = user_
                if nil != Utilities.getUserLocation() {
                    self.showTabBar()
                } else {
                    self.showLocationSelectionScreen()
                }
            } else if nil != Utilities.getUserLocation() {
                self.showTabBar()
            } else {
                self.showSocialLoginScreen()
            }
            self.getPendingFeedbackOrders()
        }
    }
    
    private func showTabBar() {
        
        //        BFLog("", tag: "User-SignedIn", level: .default)
        let tabBarController = TabBarController.instantiateFromStoryBoard(.main)
        let navController = UINavigationController(rootViewController: tabBarController)
        navController.isNavigationBarHidden = true
        if let window_ = window {
            window_.rootViewController = navController
            window_.makeKeyAndVisible()
        }
    }
    
    private func showSocialLoginScreen() {
        let loginController = SocialLoginController.instantiateFromStoryBoard(.login)
        let navController = UINavigationController(rootViewController: loginController)
        navController.isNavigationBarHidden = true
        if let window_ = window {
            window_.rootViewController = navController
            window_.makeKeyAndVisible()
        }
    }

    private func showLocationSelectionScreen() {
        let loginController = LocationViewController.instantiateFromStoryBoard(.main)
        if let window_ = window {
            window_.rootViewController = loginController
            window_.makeKeyAndVisible()
        }
    }
    
    public func getPendingFeedbackOrders() {
        
        guard sharedUtilities.isNetworkReachable() else {
            return
        }
        guard let user_ = Utilities.getUser(), let id_ = user_.id else {
            return
        }
        let requestObj: [String: AnyObject] = ["id": id_ as AnyObject]
        _ = ApiManager.shared.apiService.getFeedbackOrders(requestObj).subscribe(onNext: { [weak self](ordersList) in
            DispatchQueue.main.async(execute: {
                self?.showFeedback(list: ordersList)
            })
        }, onError: { (error) in
            if let error_ = error as? ResponseError {
                if error_.getStatusCodeFromError() == .accessTokenExpire {
                } else { }
            }
        })
    }
    
    private func showFeedback(list: [Order]) {
        if list.count > 0, let window_ = self.window, let rootController = window_.rootViewController as?  UINavigationController {
            if let rootPresentedC = rootController.presentedViewController {
                if let rootPresentedC_ = rootPresentedC as? UINavigationController, let fbpageC = rootPresentedC_.viewControllers.first as? FeedbackPageController {
                    fbpageC.feedbackOrders = list
                }
            } else {
                self.presentFeedbackControllerOn(navController: rootController, forFeedbacks: list)
            }
        }
    }
    
    private func presentFeedbackControllerOn(navController: UINavigationController, forFeedbacks ordersList: [Order]) {
        
        let feedbackPageController = FeedbackPageController.instantiateFromStoryBoard(.orderHistory)
        feedbackPageController.feedbackOrders = ordersList
        
        let navC = UINavigationController(rootViewController: feedbackPageController)
        navC.providesPresentationContextTransitionStyle = true
        navC.modalPresentationStyle = .overCurrentContext
        navC.definesPresentationContext = true
        navC.isNavigationBarHidden = true
        
        navController.present(navC, animated: true, completion: nil)
    }
        
    func showOrderDetailNotification(aDict_: [String: AnyObject]) {
        
        if nil != Utilities.getUser(),
            let id_ = aDict_["orderId"] as? Int,
            let window_ = self.window,
            let rootController = window_.rootViewController as?  UINavigationController,
            let tabC = rootController.viewControllers.first as? TabBarController {
            
            if let controller = getController(rootController: rootController, tabC: tabC, orderId: id_) {
                showOrderDetails(onController: controller, id: id_)
            } else {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: RefreshOrderDetailsNotification), object: aDict_)
            }
        }
    }
    
    private func showOrderDetails(onController: UIViewController, id: Int) {
        
        let orderDetailsController = OrderDetailsController.instantiateFromStoryBoard(.orderHistory)
        orderDetailsController.orderId = id
        
        if let controller_ = onController as? UINavigationController {
            orderDetailsController.shouldPopBack = true
            controller_.pushViewController(orderDetailsController, animated: true)
        } else if let controller_ = onController as? TabBarController {
            let navC = UINavigationController(rootViewController: orderDetailsController)
            navC.isNavigationBarHidden = true
            controller_.present(navC, animated: true, completion: nil)
        }
    }
    
    func getController(rootController: UINavigationController, tabC: TabBarController, orderId: Int) -> UIViewController? {
        
        if let presNavC = tabC.presentedViewController as? UINavigationController { //anything presented will be a navigationcontroller throughout the app
            if presNavC.presentedViewController == nil, let lastVC = presNavC.viewControllers.last as? OrderDetailsController, lastVC.orderId == orderId {
                return nil
            } else if let topNavC = presNavC.presentedViewController  as? UINavigationController { return topNavC
            } else { return presNavC
            }
        } else if tabC.presentedViewController == nil {
            if tabC.selectedIndex == 3, let navController_ = tabC.viewControllers?[tabC.selectedIndex] as? UINavigationController, let lastC_ = navController_.viewControllers.last as? OrderDetailsController, lastC_.orderId == orderId {
                return nil
            } else { return tabC
            }
        } else { return rootController //in worst case
        }
    }
    
    func refreshOrderScreen(aDict: [String: Any]?) {
        
        if Utilities.getUser() != nil {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: RefreshOrderDetailsNotification), object: aDict)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: RefreshOrderHistoryNotification), object: nil, userInfo: aDict)
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: UpdateOutletBusyBlinkNotification), object: aDict)
    }
    
    @objc func callAppSettingsAPI() {
        guard sharedUtilities.isNetworkReachable() else {
            Utilities.showToastWithMessage(NSLocalizedString("Looks like you are offline, please check internet connectivity.", comment: ""))
            return
        }
        
        _ = ApiManager.shared.apiService.fetchAppSettings().subscribe(onNext: { [weak self](appSettings) in
            // Call the app settings API. Save the App open or close state and time in user defaults and then call the start timer
            let userDefaults = UserDefaults.standard
            userDefaults.set(appSettings.openStatus, forKey: isAppOpenState)
            userDefaults.set(appSettings.message, forKey: appOpenCloseStatusMessage)
            userDefaults.set(appSettings.isCashOrCardPaymentEnabled, forKey: isEnabledCashOrCardPayment)
            userDefaults.set(appSettings.isPayTabsPaymentEnabled, forKey: isEnabledPayTabsPayment)
            userDefaults.set(appSettings.isCreditCardPaymentEnabled, forKey: isEnabledCreditCardPayment)
            userDefaults.set(appSettings.isMasterCardPaymentEnabled, forKey: isEnabledMasterCardPayment)
            userDefaults.set(appSettings.isBenfitPaymentEnabled, forKey: isEnabledCreditBenfitPayment)
            userDefaults.set(appSettings.cashOrCardDescription, forKey: cashOrCardDescription)
            userDefaults.set(appSettings.creditCardPaymentDescription, forKey: creditCardPaymentDescription)
            userDefaults.set(appSettings.benfitPayDescription, forKey: benfitPayDescription)
            userDefaults.set(appSettings.preBookingTime, forKey: preBookingDaysKey)

            userDefaults.set(true, forKey: isEnabledMasterCardPayment)

            Utilities.shared.appTimings = appSettings.appTimings
            Utilities.shared.appSettings = appSettings
            userDefaults.synchronize()
            
            self?.sharedUtilities.startTimerForAppOpenCloseState(appOpenCloseTime: appSettings.timeInMinutes ?? 0)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
        }, onError: { (error) in
            
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
    
    func keyWindows() {
        let window = UIApplication.shared.windows.last
        let upshotVC = "BKTutorialPageViewController"
        if let rootViewController = window?.rootViewController {
            let windowRootVC = NSStringFromClass(rootViewController.classForCoder)
            if upshotVC == windowRootVC {
                isUpshotWindowVisible = true
                DispatchQueue.main.async {
                    window?.makeKeyAndVisible()
                }
            }
        }
    }
}
