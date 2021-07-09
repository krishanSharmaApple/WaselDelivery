//
//  Utilities.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 15/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Reachability
import Unbox
import Toaster
import BugfenderSDK
import CryptoSwift
import Foundation

struct CustomisedTuple: Hashable, Equatable {
    
    var id: Int = -1
    var quantity: Int = -1
    
    var hashValue: Int {
        return id.hashValue ^ quantity.hashValue
    }
    
    static func == (lhs: CustomisedTuple, rhs: CustomisedTuple) -> Bool {
        return lhs.id == rhs.id && lhs.quantity == rhs.quantity
    }
    
}

struct CustomisedItem: Hashable, Equatable {
    
    var index: Int = 0
    var customisedItems: [CustomisedTuple]?

    var hashValue: Int {
        return index.hashValue
    }
    
    static func == (lhs: CustomisedItem, rhs: CustomisedItem) -> Bool {
        return lhs.index == rhs.index
    }
    
}

struct Cart {
    var cartItems = [OutletItem]()
    var instructions = ""
    var tip = 0
    var deliveryDate: Date?
}

let NetworkStatusChangeNotification = Notification.Name.reachabilityChanged

class Utilities {
    
    static let shared = Utilities()
    var isOpen = true
//    fileprivate var reachability = Reachability()
    fileprivate var timer: Timer?
    fileprivate var appOpenCloseStateTimer: Timer?

    var customItemsCount: Int = 0
    var cart: Cart = Cart()
    var cartId: String?
    var currentOutlet: Outlet?
    var cartView: CartView?
    var amenities: [Amenity]?
    var user: User?
    var isSmallDevice = (ScreenHeight == 568.0 ) ? true : false
    var enteredForeground = false
    let cameraIconImage = UIImage(named: "cameraIcon")
    var appTimings: [OutletTimings]?
    var appSettings: AppSettings?

    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        return formatter
    }()

    fileprivate init() { }
    
// MARK: - Reachability Methods
    
    fileprivate func startReachabilityNotifier() {
//        do {
//            try self.reachability?.startNotifier()
//        } catch let error as NSError {
//            Utilities.log(error as AnyObject, type: .error)
//        }
    }
    
    func setupReachability() {
        self.startReachabilityNotifier()
    }
    
    func isNetworkReachable() -> Bool {
        if ApiManager.shared.apiServiceType == APIServiceType.staticService {
            return true
        }
        return true // reachability?.isReachable ?? false
    }
    
    func removeReachabilityObserver() {
//        reachability?.stopNotifier()
//        reachability = nil
    }

    func isIphoneX() -> Bool {
        var isPhoneX = false
        if #available(iOS 11.0, *) {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            if let topInsets: CGFloat = appDelegate?.window?.safeAreaInsets.top {
                if topInsets > 20 {
                    isPhoneX = true
                }
            }
        }
        return isPhoneX
    }
    
    func screenShotOfTabBarView(referenceView: UIView, cropRect: CGRect?) -> UIImage? {
        UIGraphicsBeginImageContext((referenceView.bounds.size))
        guard let renderContext = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        referenceView.layer.render(in: renderContext)
        let screenShotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let cropRect_ = cropRect {
            if let imageRef = screenShotImage?.cgImage?.cropping(to: cropRect_) {
                return UIImage(cgImage: imageRef)
            }
        }
        return screenShotImage
    }

// MARK: - Timer Methods
    
    func startTimer() {
        cancelTimer()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerNotification), userInfo: nil, repeats: true)
        if let timer_ = timer {
            RunLoop.current.add(timer_, forMode: RunLoop.Mode.common)
        }
    }
    
    func cancelTimer() {
        if let timer_ = timer, timer_.isValid {
            timer?.invalidate()
        }
    }
    
    @objc func timerNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: UpdateStatusAnimationNotification), object: nil)
    }
    
    class func fetchOutletName(_ outlet: Outlet) -> String {
        var outletName = outlet.name ?? ""
        let nameStringArray = outletName.components(separatedBy: "--")
        if 0 < nameStringArray.count {
            outletName = nameStringArray[0]
        }
        return outletName
    }
    
    class func fetchOutletLocationName(_ outlet: Outlet) -> String {
        var locationNameString = outlet.name ?? ""
        let nameAndLocationStringArray = locationNameString.components(separatedBy: "--")
        if 1 < nameAndLocationStringArray.count {
            locationNameString = nameAndLocationStringArray.last?.trim() ?? ""
        }
        return locationNameString
    }
    
    class func isOutletOpen(_ outlet: Outlet) -> (isOpen: Bool, message: String) {
        if 1 != outlet.openStatus {//openStatus-> 1: closed, 2: Busy, 3: Open
            return (true, outlet.opentime ?? "")
        }
        return (false, outlet.opentime ?? "")
        
//        if let firstShiftStartTime_ = outlet.firstShiftStartTime, let firstShiftEndTime_ = outlet.firstShiftEndTime {
//            
//            let dateFormatString = "hh:mm a"
//            
//            let ctm = TimeZone.current.minutesFromGMT
//            let currentDateInMin = (self.getMinuteFromHour(date: Date()) + ctm) % 1440
//            
//            var firstShiftStartTimeInMin = 0
//            var firstShiftEndTimeInMin = 0
//            
//            var secondShiftStartTimeInMin = 0
//            var secondShiftEndTimeInMin = 0
//
//            let firstShiftStartTime = self.getSystemDateString(date: firstShiftStartTime_, dateFormatString)
//            let firstShiftEndTime = self.getSystemDateString(date: firstShiftEndTime_, dateFormatString)
//            
//            var secondShiftStartTime = ""
//            var secondShiftEndTime = ""
//
//            
//            firstShiftStartTimeInMin = (self.getMinuteFromHour(date: firstShiftStartTime_) + ctm) % 1440
//            firstShiftEndTimeInMin = (self.getMinuteFromHour(date: firstShiftEndTime_) + ctm) % 1440
//            
//            if let secondShiftStartTime_ = outlet.secondShiftStartTime, let secondShiftEndTime_ = outlet.secondShiftEndTime {
//                secondShiftStartTimeInMin = (self.getMinuteFromHour(date: secondShiftStartTime_) + ctm) % 1440
//                secondShiftEndTimeInMin = (self.getMinuteFromHour(date: secondShiftEndTime_) + ctm) % 1440
//                
//                secondShiftStartTime = self.getSystemDateString(date: secondShiftStartTime_, dateFormatString)
//                secondShiftEndTime = self.getSystemDateString(date: secondShiftEndTime_, dateFormatString)
//
//            }
//            
//            let dates = [(start: firstShiftStartTime, end: firstShiftEndTime), (start: firstShiftEndTime, end: secondShiftStartTime), (start: secondShiftStartTime, end: secondShiftEndTime)]
//            var sets = [(start: firstShiftStartTimeInMin, end: firstShiftEndTimeInMin)]
//            if secondShiftStartTimeInMin > 0 || secondShiftEndTimeInMin > 0 {
//                sets.append((start: firstShiftEndTimeInMin, end: secondShiftStartTimeInMin))
//                sets.append((start: secondShiftStartTimeInMin, end: secondShiftEndTimeInMin))
//            }
//            var openText = ""
//            var closeText = ""
//            var isOpen = false
//            
//            for (index, set) in sets.enumerated() {
//                if set.start < set.end {
//                    if set.start ... set.end ~= currentDateInMin {//open
//                        if index == 1 {
//                            isOpen = false
//                            let date_ = dates[index]
//                            closeText = "Closed Now, Opens by \(date_.end)"
//                        } else {
//                            isOpen = true
//                            let date_ = dates[index]
//                            openText = "\(date_.start) - \(date_.end)"
//                        }
//                        break
//                    } else if currentDateInMin < set.start {
//                        isOpen = false
//                        let date_ = dates[index]
//                        closeText = "Closed Now, Opens by \(date_.start)"
//                        break
//                    } else {
//                        isOpen = false
//                        closeText = "We are closed for today"
//                        continue
//                    }
//                } else if (currentDateInMin > set.start || currentDateInMin < set.end) {//open
//                    if index == 1 {
//                        if set.start == set.end {
//                            continue
//                        }
//                        isOpen = false
//                        let date_ = dates[index]
//                        closeText = "Closed Now, Opens by \(date_.end)"
//                    } else {
//                        isOpen = true
//                        let date_ = dates[index]
//                        openText = "\(date_.start) - \(date_.end)"
//                    }
//                    break
//                } else {
//                    isOpen = false
//                    closeText = "We are closed for today"
//                    continue
//                }
//            }
//            
//            return (isOpen, isOpen ? openText : closeText)
//            
//        } else if let timing_ = outlet.timing {
//            if timing_ == "24 HOURS" {
//                return (true, "24 HOURS")
//            } else {
//                return (false, timing_.count > 0 ? timing_ : "We are closed for today")
//            }
//        }
//        return (true, "")
    }

    class func isOutletOpenForSchudledDate(_ outletTimings: OutletTimings, schudledDate: Date) -> (isOpen: Bool, message: String) {

        func getTimeDetails(date: Date) -> (hours: Int, minutes: Int, seconds: Int) {
            var calendar = Calendar.current
            if let utcTimeZone = TimeZone(identifier: "UTC") {
                calendar.timeZone = utcTimeZone
            }
            let hour = calendar.component(.hour, from: date)
            let minutes = calendar.component(.minute, from: date)
            let seconds = calendar.component(.second, from: date)
            return (hour, minutes, seconds)
        }
        
        func dummyDateForTimeSlot(date: Date) -> Date {
            let calendar = Calendar.current
            var dummyDate_ = Date(timeIntervalSinceReferenceDate: 0) // Initiates date at 2001-01-01 00:00:00 +0000
            let newDateComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
            dummyDate_ = calendar.date(byAdding: newDateComponents, to: dummyDate_) ?? Date()
            return dummyDate_
        }
        
        // Verify with app timing
        if false == Utilities.isWaselDeliveryOpen() {
            return (false, "We are closed for today")
        }
        
        // Verify the 24hrs format enabled
        if let is24hrs_ = outletTimings.is24hrs, true == is24hrs_ {
            return (true, "24 HOURS")
        }

        let schudledLocalTime_ = dummyDateForTimeSlot(date: schudledDate)
        var messageString = "Please choose the time between : "

        if let firstShiftStartDateAndTime_ = outletTimings.firstShiftStartDateAndTime, false == firstShiftStartDateAndTime_.isEmpty {
            let firstShiftStartTime_ = Utilities.getUtcDate(utcDateString: firstShiftStartDateAndTime_, dateformatString: "HH:mm:ss") ?? Date()
            
            if let firstShiftDateAndEndTime_ = outletTimings.firstShiftDateAndEndTime, false == firstShiftDateAndEndTime_.isEmpty {
                let firstShiftEndTime_ = Utilities.getUtcDate(utcDateString: firstShiftDateAndEndTime_, dateformatString: "HH:mm:ss") ?? Date()

                let firstShiftStartLocalTime_ = dummyDateForTimeSlot(date: firstShiftStartTime_)
                var firstShiftEndLocalTime_ = dummyDateForTimeSlot(date: firstShiftEndTime_)
                if firstShiftEndLocalTime_ < firstShiftStartLocalTime_ {
                    firstShiftEndLocalTime_.addTimeInterval(24 * 60 * 60)
                }

                if (firstShiftStartLocalTime_.compare(schudledLocalTime_) == .orderedAscending) && (firstShiftEndLocalTime_.compare(schudledLocalTime_) == .orderedDescending) {
                    return (true, "")
                }
               
                let firstShiftStartTimeDetails = getTimeDetails(date: firstShiftStartLocalTime_)
                let firstShiftStartTimeString = String(firstShiftStartTimeDetails.hours) + ":" + String(firstShiftStartTimeDetails.minutes) + ":" + String(firstShiftStartTimeDetails.seconds)

                let firstShiftEndTimeDetails = getTimeDetails(date: firstShiftEndLocalTime_)
                let firstShiftEndTimeString = String(firstShiftEndTimeDetails.hours) + ":" + String(firstShiftEndTimeDetails.minutes) + ":" + String(firstShiftEndTimeDetails.seconds)

                messageString +=  "\(firstShiftStartTimeString)-\(firstShiftEndTimeString)"
            }
        }
        
        if let enableSecondShift_ = outletTimings.enableSecondShift, true == enableSecondShift_ {
            if let secondShiftStartDateAndTime_ = outletTimings.secondShiftDateAndStartTime, false == secondShiftStartDateAndTime_.isEmpty {
                let secondShiftStartTime_ = Utilities.getUtcDate(utcDateString: secondShiftStartDateAndTime_, dateformatString: "HH:mm:ss") ?? Date()
                
                if let secondShiftDateAndEndTime_ = outletTimings.secondShiftDateAndEndTime, false == secondShiftDateAndEndTime_.isEmpty {
                    let secondShiftEndTime_ = Utilities.getUtcDate(utcDateString: secondShiftDateAndEndTime_, dateformatString: "HH:mm:ss") ?? Date()

                    let secondShiftStartLocalTime_ = dummyDateForTimeSlot(date: secondShiftStartTime_)
                    var secondShiftEndLocalTime_ = dummyDateForTimeSlot(date: secondShiftEndTime_)
                    if secondShiftEndLocalTime_ < secondShiftStartLocalTime_ {
                        secondShiftEndLocalTime_.addTimeInterval(24 * 60 * 60)
                    }

                    if (secondShiftStartLocalTime_.compare(schudledLocalTime_) == .orderedAscending) && (secondShiftEndLocalTime_.compare(schudledLocalTime_) == .orderedDescending) {
                        return (true, "")
                    }

                    let secondShiftStartTimeDetails = getTimeDetails(date: secondShiftStartLocalTime_)
                    let secondShiftStartTimeString = String(secondShiftStartTimeDetails.hours) + ":" + String(secondShiftStartTimeDetails.minutes) + ":" + String(secondShiftStartTimeDetails.seconds)

                    let secondShiftEndTimeDetails = getTimeDetails(date: secondShiftEndLocalTime_)
                    let secondShiftEndTimeString = String(secondShiftEndTimeDetails.hours) + ":" + String(secondShiftEndTimeDetails.minutes) + ":" + String(secondShiftEndTimeDetails.seconds)
                    messageString +=  " OR " + "\(secondShiftStartTimeString)-\(secondShiftEndTimeString)"
                }
            }
        }
        return (false, messageString)
    }
    
    class func getMinuteFromHour(date: Date) -> Int {
        
        //        let dateFormatter = DateFormatter()
        var calendar = Calendar.current
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
        }
        
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        let totalMinutes = (hour * 60) + minutes + (seconds/60)
        
        debugPrint("hours = \(hour):\(minutes):\(seconds)")
        
        return totalMinutes % 1440
    }
    
    class func getWeekDay(date: Date) -> Int {
        let calendar = Calendar.current
        /*if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
        }*/
        
        let weekday = calendar.component(.weekday, from: date)
        return weekday - 1
    }
    
// MARK: - TimeZone from UTC to Local
    
    class func getUtcDate(utcDateString: String, dateformatString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateformatString
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Fixes non 24 hour mode on device
        let utcDate = dateFormatter.date(from: utcDateString)
        return utcDate
    }

    class func getSystemDateString(date: Date?, _ dateformatString: String) -> String {
        guard let date_ = date else {
            return ""
        }
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.ReferenceType.system
        dateFormatter.dateFormat = dateformatString
        let systemDateString = dateFormatter.string(from: date_)
        return systemDateString
    }

    class func getUTCDateFromUTCTime(utcDateString: String, dateformatString: String) -> Date? {
        
        let utcDate_ = getUtcDate(utcDateString: utcDateString, dateformatString: "HH:mm:ss")
        return utcDate_
    }
    
    private class func getCurrentDateStringInLocalTimeZone(dateformatString: String) -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateformatString
        dateFormatter.timeZone = TimeZone.ReferenceType.system
        let utcDateString = dateFormatter.string(from: Date())
        return utcDateString
    }
    
// MARK: - Alert & Activity Methods
    
    class func showAlertMessage(_ message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
    }

    class func showMasterCardAlertMessage(_ message: String) {
        let alert = UIAlertController(title: message, message: "Please try again or use another card or payment method", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
    }

    class func showBenefitAlertMessage(_ message: String) {
        let alert = UIAlertController(title: message, message: "Please try again or use another card or payment method", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
    }

    class func showToastWithMessage(_ message: String, position: ToastPositon = .bottom, duration: TimeInterval = 2.0) {
        if let currentToast = ToastCenter.default.currentToast { currentToast.cancel() }
//        let toast = Toast(text: message)
        let toast = Toast(text: message, duration: duration)
        toast.view.bottomOffsetPortrait = position.bottomOffset
        toast.show()
    }
    
    /// Displays the HUD
    ///
    /// - Parameters:
    ///   - view: a sub class of UIView. in which HUD needs to be diaplayed.
    ///           pass `nil` value for displaying HUD in full screen
    ///   - message: message for describing the purpose of displaying HUD
    class func showHUD(to view: UIView?, _ message: String?) {
        DispatchQueue.main.async {
            if let view = view {
                Hud.shared.showHUD(to: view, message)
            } else if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let window = appDelegate.window {
                Hud.shared.showHUD(to: window, message)
            }
        }
//        guard let `view` = view else {
//            return
//        }
//
//        Utilities.hideHUD(from: view)
//        UIApplication.shared.beginIgnoringInteractionEvents()
//        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 70.0, height: 70.0))
//        imageView.tag = 1901
//        imageView.backgroundColor = UIColor.clear
//        var images = [UIImage]()
//
//        for index in 1...120 {
//            let imageName =  String(format: "loading%03d", index)
//            images.append(UIImage(named: imageName)!)
//        }
//
//        imageView.animationImages = images
//        imageView.animationDuration = 2.6
//        view.addSubview(imageView)
//        imageView.center = view.center
//        imageView.startAnimating()
    }
    
    class func hideHUD(from view: UIView?) {
        DispatchQueue.main.async {
            Hud.shared.hideHUD()
        }

//        guard let `view` = view else {
//            return
//        }
//        UIApplication.shared.endIgnoringInteractionEvents()
//        let loadingImage = view.viewWithTag(1901)
//        if let loadingImage_ = loadingImage {
//            loadingImage_.removeFromSuperview()
//        }
    }
    
    class func getStoryBoard(forName name: StoryBoard) -> UIStoryboard {
        return UIStoryboard(name: name.rawValue, bundle: nil)
    }

// MARK: - Cart Methods
    
    func updateCart(_ item: OutletItem) {
        
        if item.cartQuantity > 0 {
            if !cart.cartItems.contains(where: { $0 === item }) {
                item.cartIndex = Utilities.shared.cart.cartItems.count + 1

                // set cartId while adding first item to cart (if not exist)
                if cart.cartItems.isEmpty && cartId == nil {
                    // set UUID string as cart ID
                    cartId = UUID().uuidString
                }

                cart.cartItems.append(item)
            } else {
                if let index = cart.cartItems.index(where: { $0 === item }) {
                    cart.cartItems[index] = item
                }
            }
        } else {
            if cart.cartItems.contains(where: { $0 === item }) {
                if let index = cart.cartItems.index(where: { $0 === item }) {
                    clearCustomizationForItem(item)
                    cart.cartItems.remove(at: index)
                }
            }

            // delete cart id if all Items are deleted from cart
            if cart.cartItems.isEmpty {
                cartId = nil
            }
        }
        reloadCartView()
    }
    
    func clearCustomizationForItem(_ item: OutletItem) {
        if let customizeItems = item.customisationItems {
            
            _ = customizeItems.map ({ (category) -> CustomizeCategory in
                
                if let items_ = category.items {
                    _ = items_.map { $0.isCheck = false; $0.quantity = 0 }
                    if category.categoryMode == .anyOne {
                        for (index, customizeItem) in items_.enumerated() {
                            customizeItem.isRadioSelectionEnabled = (index == 0) ? true : false
                            customizeItem.quantity = (index == 0) ? 1 : 0
                        }
                    }
                }
                return category
            })
        }
        if nil != item.parent {
            item.parent = nil
        }
        item.cartIndex = 0
    }
    
    func reloadCartView() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let navController = appDelegate.window?.rootViewController as? UINavigationController else {
            return
        }
        if let tabController_ = navController.viewControllers.first as? TabBarController {
            if Utilities.shared.cart.cartItems.count > 0 {
                guard let topViewController = appDelegate.window?.rootViewController?.topMostViewController() else {
                    return
                }
                if cartView == nil {
                    let statusBarFrame: CGRect = UIApplication.shared.statusBarFrame
                    let statusBarHieght: CGFloat = 20.0 //(true == isIphoneX()) ? 44.0 : 20.0
                    let bottomBarHeight: CGFloat = 60.0 //(true == isIphoneX()) ? 84.0 : 60.0
                    let topPosition = (bottomBarHeight + (statusBarHieght >= statusBarFrame.size.height ? 0.0 : (statusBarFrame.size.height - statusBarHieght)))
                    cartView = CartView(frame: CGRect(x: 0.0, y: ScreenHeight - topPosition, width: ScreenWidth, height: bottomBarHeight))
                    if let cartView_ = cartView {
                        tabController_.view.addSubview(cartView_)
                    }
                    NotificationCenter.default.post(name: Notification.Name(rawValue: OrderDetailsTableViewHeightNotification), object: nil, userInfo: nil)
                }
                if topViewController is CartViewController {
                    cartView?.isHidden = true
                } else {
                    cartView?.isHidden = false
                }
                cartView?.reloadData()
            } else {
                if cartView != nil {
                    cartView?.removeFromSuperview()
                    cartView = nil
                    NotificationCenter.default.post(name: Notification.Name(rawValue: OrderDetailsTableViewHeightNotification), object: nil, userInfo: nil)
                }
            }
        }
    }
    
    func clearCart(isManualClear: Bool? = false) {

        cart.cartItems = cart.cartItems.map({ (item) -> OutletItem in
            item.cartQuantity = 0
            return item
        })
        
        for item in cart.cartItems {
            if let customizationItems_ = item.customisationItems {
                _ = customizationItems_.compactMap { $0.items.flatMap { $0 } }.flatMap { $0 }.filter { $0.quantity > 0 || $0.isCheck }.map { $0.quantity = 0; $0.isCheck = false }
            }
            item.cartIndex = 0
            clearCustomizationForItem(item)
        }
        
        cart.cartItems.removeAll()
        cart.instructions = ""
        cart.tip = 0
        cart.deliveryDate = nil
        cartId = nil
        if cartView != nil {
            cartView?.removeFromSuperview()
            cartView = nil
        }
    }
    
    func getTotalItems() -> Int {
        if cart.cartItems.count > 0 {
            let count = Utilities.shared.cart.cartItems.reduce(0) { $0 + $1.cartQuantity }
            return count
        }
        return 00
    }
    
    func getTotalCost() -> Double {
        if cart.cartItems.count > 0 {
            let price: Double = Utilities.shared.cart.cartItems.reduce(0) { $0 + (($1.price ?? 0.0) * Double($1.cartQuantity)) }
            let customisationcost = getCustomizationCost()
            let total = price + customisationcost
            return total
        }
        return 0.000
    }
    
    func getCustomizationCost() -> Double {
        
        let prices = Utilities.shared.cart.cartItems.map { outlet -> Double in
        
            if let customisationItems_ = outlet.customisationItems, customisationItems_.count > 0 {
                let customisationItems = customisationItems_.compactMap { $0.items }.flatMap { $0 }
                return Double(outlet.cartQuantity) * customisationItems.reduce(0.0) { acc, item in
                    return acc + (item.price ?? 0.0) * Double(item.quantity)
                }
            }
            return Double(0.0)
        }
        let customizationPrice: Double = prices.reduce(0) { $0 + ( $1 ) }
        return customizationPrice
    }
    
// MARK: - LifeCycle Methods
    
    deinit {
        removeReachabilityObserver()
    }
    
// MARK: - Dynamic Item Customization Methods
    
    class func getItemViewHeightForItem(_ item_: OutletItem) -> CGFloat {
        var height: CGFloat = 0.0
        if let cartItems_ = item_.cartItems {
            height = cartItems_.reduce (0.0) { $0 + Utilities.getCustomizationStringHeightFor(item: $1) } + (CGFloat(cartItems_.count) * 10.0)//(ItemCell itemspacing - 10.0)
        }
        return height
    }
    
    class func getCustomizationStringHeightFor(item: OutletItem) -> CGFloat {
        
        let customizationString = Utilities.getCustomizationString(item: item)
        let height = Utilities.getSizeForText(text: customizationString, font: UIFont.montserratRegularWithSize(14.0), fixedWidth: ScreenWidth - 133.0).height//133 = 99(label to boundaries) + (17 * 2)(collectionview to boundaries)
        return height + 43.0//(ItemCell default height(43.0))
    }
    
    class func getCustomizationString(item: OutletItem) -> String {
        var customizationString = ""
        if let c_ = item.customisationItems {
            _ = c_.map({ (customizeCategory) -> CustomizeCategory in
                if let cI_ = customizeCategory.items {
                    _ = cI_.map({ (customizeItem) -> CustomizeItem in
                        if let name_ = customizeItem.name, customizeItem.quantity > 0 {
                            customizationString.append("\(name_) x \(customizeItem.quantity )")
                        }
                        return customizeItem
                    })
                }
                return customizeCategory
            })
        }
        return customizationString
    }
    
// MARK: - AccessToken
    
    class func setAccessTokens(tokens: (access: String?, refresh: String?)) {
        
        let userDefaults = UserDefaults.standard
        if let accessToken = tokens.access, accessToken.length > 0 {
//            BFLog("Token %@", accessToken , tag: "AccessToken", level: .default)
            userDefaults.set(accessToken, forKey: AccessToken)
        }
        if let refreshToken = tokens.refresh, refreshToken.length > 0 {
            userDefaults.set(refreshToken, forKey: RefreshToken)
        }
        userDefaults.synchronize()
    }
    
    class func getAccessToken() -> String? {
        let userDefaults = UserDefaults.standard
        let accessToken = userDefaults.object(forKey: AccessToken) as? String
        return accessToken
    }
    
    class func getRefreshToken() -> String? {
        let userDefaults = UserDefaults.standard
        let refreshToken = userDefaults.object(forKey: RefreshToken) as? String
        return refreshToken
    }
    
// MARK: - UserLocation Methods
    
    class func getUserLocation() -> UserLocation? {
        let userDefaults = UserDefaults.standard
        let userLocation = userDefaults.object(forKey: UserSelectedLocation) as? [String: AnyObject]
        do {
            if let userLocation_ = userLocation {
                let location: UserLocation = try unbox(dictionary: userLocation_)
                return location
            }
            return nil
        } catch {
            return nil
        }
    }
 
    class func setUserLocation(_ locationObj: [String: Any], shouldUseCurrentlocation: Bool) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(locationObj, forKey: UserSelectedLocation)
        userDefaults.set(shouldUseCurrentlocation, forKey: isCurrentLocation)
        userDefaults.synchronize()
    }
    
    class func shouldUseCurrentLocation() -> Bool {
        
        let userDefaults = UserDefaults.standard
        if let shouldUseCurrentLoc = userDefaults.value(forKey: isCurrentLocation) as? Bool {
            return shouldUseCurrentLoc
        } else {
            return false
        }
    }
    
    class func setUserObject(_ userObject: User) {
        let userDefaults = UserDefaults.standard
        
        var user = [String: Any]()
        if let id_ = userObject.id {
            user["id"] = id_
        }
        if let mobile_ = userObject.mobile {
            user["mobile"] = mobile_
        }
        if let name_ = userObject.name {
            user["name"] = name_
        }
        if let email_ = userObject.email {
            user["email"] = email_
        }
        if let imageUrl_ = userObject.imageUrl {
            user["imageUrl"] = imageUrl_
        }
//        BFLog("Email:%@ UID:%@", userObject.email ?? "", userObject.id ?? "" , tag: "User", level: .default)
        userDefaults.set(user, forKey: LoggedInUser)
        userDefaults.synchronize()
    }
    
    class func getUser() -> User? {
        let userDefaults = UserDefaults.standard
        let defaultsUser = userDefaults.object(forKey: LoggedInUser) as? [String: AnyObject]
        do {
            if let user_ = defaultsUser {
                let user: User = try unbox(dictionary: user_)
                return user
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    class func updateSearchLocationHistoryWith(locaionObj: [String: Any]) {
        
        let userDefaults = UserDefaults.standard
        var historyResults = userDefaults.object(forKey: LocationSearchHistory) as? [[String: Any]]
        if historyResults == nil {
            historyResults = [[String: AnyObject]]()
        }
        
        let objIndex = historyResults?.index(where: { (obj) -> Bool in
            let latitude1 = String(describing: obj["latitude"])
            let latitude2 = String(describing: locaionObj["latitude"])
            return latitude1 == latitude2
        })
        // remove duplicates and insert
        if let index = objIndex, index >= 0 {
            historyResults?.remove(at: index)
        }
        historyResults?.insert(locaionObj, at: 0)
        
        // store only 10 results
        if let historyResults_ = historyResults, 10 < historyResults_.count {
            historyResults = Array(historyResults_[0..<10])
        }
        userDefaults.set(historyResults, forKey: LocationSearchHistory)
        userDefaults.synchronize()
    }
    
    class func isUserLoggedIn() -> Bool {
        return Utilities.getUser() != nil
    }
    
    class func logoutUser() {
        
        GoogleAPIClient.logout()
        FacebookAPIClient.logout()
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: LoggedInUser)
        userDefaults.synchronize()
        Utilities.shared.user = nil
    }
    
// MARK: - Logging
    
    class func log(_ obj: AnyObject, type: LoggingType) {

        DispatchQueue.main.async {
            guard let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            switch type {
            case .trace: appdelegate.log.trace(obj)
            case .debug: appdelegate.log.debug(obj)
            case .info: appdelegate.log.info(obj)
            case .warning: appdelegate.log.warning(obj)
            case .error: appdelegate.log.error(obj)
            }
        }
    }
    
// MARK: - Validations
    
    class func isValidEmail(testStr: String) -> Bool {
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    class func isStringContainsAlphaAndSpecialCharacters(_ string: String) -> Bool {
        return string.rangeOfCharacter(from: NSCharacterSet.decimalDigits.inverted) != nil
    }

// MARK: - DynamicTextSize
    
    class func getSizeForText(text: String, font: UIFont, fixedWidth: CGFloat = CGFloat(Float.greatestFiniteMagnitude), fixedHeight: CGFloat = CGFloat(Float.greatestFiniteMagnitude)) -> CGSize {
        
        let aRect = (text as NSString).boundingRect(with: CGSize(width: fixedWidth, height: fixedHeight), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return aRect.size
    }
    
// MARK: - Name Validation

    func isValidCharacterForName(textField: UITextField, string: String, forLength: Int) -> Bool {
        let charactesAllowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ")
        let isSpace = (string.isEmpty) ? true : false
        var isStringOrCharacterAllowed = false
        if nil != string.rangeOfCharacter(from: charactesAllowed) {
            isStringOrCharacterAllowed = true
        } else {
            isStringOrCharacterAllowed = false
        }
        let isValidCharacter = (isStringOrCharacterAllowed || (isSpace == true)) ? true : false
        return isValidCharacter && forLength <= MaxNameCharacters
    }
    
// MARK: - OrderProcessingMethods
    
    class func getOrderItemsDictionary() -> [[String: AnyObject]] {
        
        var items = [[String: AnyObject]]()
        
        for item in Utilities.shared.cart.cartItems {
            var itemDict = [String: AnyObject]()
            
            itemDict[NameKey] = item.name as AnyObject
            itemDict[ItemIdKey] = item.id as AnyObject
            itemDict[QuantityKey] = item.cartQuantity as AnyObject
            itemDict[PriceKey] = item.price as AnyObject
            itemDict[ItemInstructionKey] = item.instructions as AnyObject

            if let imageUrlString_ = item.imageUrl {
                let imageUrlStringArray_ = imageUrlString_.components(separatedBy: imageBaseUrl)
                var imagesArray = [String]()
                if 1 < imageUrlStringArray_.count {
                    if let imageUrlStr_ = imageUrlStringArray_.last {
                        imagesArray.append(imageUrlStr_)
                    }
                }
                itemDict[ProductImageKey] = imagesArray as AnyObject
            }
            
            itemDict[ItemDescriptionKey] = item.itemDescription as AnyObject?
            if let customizationItems_ = item.customisationItems {
                let customItems = customizationItems_.compactMap { $0.items.flatMap { $0 } }.flatMap { $0 }
                let filterItems = customItems.filter { $0.quantity > 0 || $0.isCheck || $0.isRadioSelectionEnabled }
                if filterItems.count > 0 {
                    var customization = [[String: AnyObject]]()
                    for customItem in filterItems {
                        var customDict = [String: AnyObject]()
                        customDict[NameKey] = customItem.name as AnyObject?
                        customDict[CustomItemIdKey] = customItem.id as AnyObject?
                        customDict[PriceKey] = customItem.price as AnyObject?
                        customDict[QuantityKey] = customItem.quantity as AnyObject?
                        customization.append(customDict)
                    }
                    itemDict[CustomItemsKey] = customization as AnyObject?
                }
            }
            var customFields = [[String: AnyObject]]()
            if let isSpicy_ = item.isSpicy {
                var spicyDict: [String: Any] = ["field": ["field": OutletItemCustomFieldType.spicy.rawValue as AnyObject]]
                spicyDict["value"] = isSpicy_ as AnyObject?
                customFields.append(spicyDict as [String: AnyObject])
            }
            if let isVeg_ = item.isVegItem {
                var vegDict: [String: Any] = ["field": ["field": OutletItemCustomFieldType.cuisineType.rawValue as AnyObject]]
                vegDict["value"] = isVeg_ as AnyObject?
                customFields.append(vegDict as [String: AnyObject])
            }
            if customFields.count > 0 {
                itemDict[OutletItemCustomFields] = customFields as AnyObject?
            }
            items.append(itemDict)
        }
        return items
    }
    
// MARK: - SupportMethods
    
    class func shouldHideTabCenterView(_ tabC: UITabBarController?, _ shouldHide: Bool) {
        if let tabC_ = tabC as? TabBarController {
            tabC_.shouldHideTabCenterButton = shouldHide
        }
    }
    
    class func convertTextToDictionary(text: String) -> [String: AnyObject]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return nil
    }
    
    class func convertArrayToJson(from object: Any) -> String? {
        if let objectData = try? JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions(rawValue: 0)) {
            let objectString = String(data: objectData, encoding: .utf8)
            return objectString
        }
        return nil
    }
    
    class func formSpecialOrder(_ order: Order) -> SpecialOrder {
        
        var items_ = [[String: AnyObject]]()
        if let items = order.items {
            items_ = items.map ({ (item) -> [String: AnyObject]? in
                if let name_ = item.name {
                    var productImage_ = [String]() as AnyObject
                    if let imageURL_ = item.imageUrls?.first {
                        var imagesArray = [String]()
                        imagesArray.append(imageURL_ as String)
                        productImage_ = imagesArray as AnyObject
                    }
                    return [NameKey: name_ as AnyObject, QuantityKey: 1 as AnyObject, ProductImageKey: productImage_]
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

    class func getDistanceAttString(outlet: Outlet) -> NSAttributedString {
        
        if let distance_ = outlet.distance {
            let distanceNumber = Float(distance_) ?? 0.0
            let roundedDistance = Float(round(distanceNumber * 10) / 10)
            let distText = String(format: "%.1f", roundedDistance) + " KM"
            let attrString = NSMutableAttributedString(string: distText)
            attrString.addAttribute(kCTFontAttributeName as NSAttributedString.Key, value: UIFont.montserratLightWithSize(10.0), range: NSRange(location: distText.count - 3, length: 3))
            return attrString
        } else {
            return NSAttributedString(string: "")
        }
    }
    
    class func getDeliveryChargeAttString(outlet: Outlet) -> NSAttributedString {
        if let deliveryCharge_ = outlet.deliveryCharge {
            if deliveryCharge_ > 0 {
                let charge_ = Float(round(deliveryCharge_ * 1000) / 1000)
                let attrString = NSMutableAttributedString(string: "BD \(String(format: "%.3f", charge_))")
                attrString.addAttribute(kCTFontAttributeName as NSAttributedString.Key, value: UIFont.montserratLightWithSize(10.0), range: NSRange(location: 0, length: 3))
                return attrString
            } else if deliveryCharge_ == -1 {
                return NSAttributedString(string: NotServingLocationMessage)
            } else {
                return NSAttributedString(string: "Free Delivery")
            }
        } else {
            return NSAttributedString(string: "")
        }
    }

    /// Returns delivery charges srting in the formatt "Delivery Fee: BD 0.000"
    class func getDeliveryChargeStringFrom(outlet: Outlet) -> String {
        var deliveryChargeString = ""
        if outlet.isFleetOutLet ?? false {
            deliveryChargeString = outlet.ownFleetDescription ?? ""
        } else if let deliveryCharge = outlet.deliveryCharge {
            if deliveryCharge > 0 {
                deliveryChargeString = String(format: "%.3f", Float(deliveryCharge.roundedToBD))
            } else if deliveryCharge == 0 {
                deliveryChargeString = "Free"
            } else if deliveryCharge == -1 {
                return NotServingLocationMessage
            }
        }
        return deliveryChargeString
    }
    /// Returns minimum order srting in the formatt "Handling Fee: BD 0.000" or "Handling Fee: 2.0%"
    class func getMinimumOrderStringFrom(outlet: Outlet) -> String {
        let minOrder = Float((outlet.minimumOrderValue ?? 0).roundedToBD)
        if minOrder > 0 {
            let minOrderString = String(format: "%.2f", minOrder)
            return "Min-Order: BD \(minOrderString)"
        }
        return ""
    }
    /// Returns handle fee srting in the formatt "Min-Order: BD 0.000"
    class func getHandleFeeStringFrom(outlet: Outlet) -> String {
        var handleFee = Float(outlet.handleFee.roundedToBD)
        var handleFeeType = outlet.handleFeeType ?? "PERCENTAGE"

        if !(outlet.isPartnerOutLet ?? false) && handleFee == 0, let appSettings = Utilities.shared.appSettings {
            handleFee = Float(appSettings.handleFee.roundedToBD)
            handleFeeType = appSettings.handleFeeType ?? "PERCENTAGE"
        }

        if handleFee <= 0 {
            return ""
        }

        var handleFeeString: String = "BD 0.00"

        if handleFeeType == "AMOUNT" {
            handleFeeString = "BD " + String(format: "%.2f", handleFee)
        } else {
            handleFeeString = "\(String(format: "%.1f", handleFee))%"
        }

        return "Handling Fee: \(handleFeeString)"
    }
    
    class func format(value: Double) -> String {
         return String(format: "%.3f", value)
    }

    // MARK: - App open close state Methods

    class func isWaselDeliveryOpen() -> Bool {
        let userDefaults = UserDefaults.standard
        if let isAppOpen = userDefaults.value(forKey: isAppOpenState) as? Bool {
            return isAppOpen
        }
        return true
    }

    class func removeTransparentView() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let transparentView = appDelegate.window?.viewWithTag(90000) { // get the TransparentView
                transparentView.removeFromSuperview()
            }
        }
    }
    
    class func shouldHideTransparentView(shouldShowTransparentView: Bool = false) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let transparentView = appDelegate.window?.viewWithTag(90000) { // get the TransparentView
                transparentView.isHidden = shouldShowTransparentView
            }
        }
    }

    class func showTransparentView(shouldShowTransparentBg: Bool = false, isFromOrderAnythingScreen: Bool = false, showBannerView: Bool = true) {
        self.removeTransparentView()
        if false == Utilities.isWaselDeliveryOpen() {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                if let rootNavController = appDelegate.window?.rootViewController as? UINavigationController {
                    if let rootPresentedC = rootNavController.presentedViewController {
                        if let rootPresentedC_ = rootPresentedC as? UINavigationController, nil != rootPresentedC_.viewControllers.first as? FeedbackPageController {
                            return //Feedback screen
                        }
                    }
                    if let tabBarController = rootNavController.viewControllers.first as? TabBarController {
                        if tabBarController.selectedIndex == 1, let navController_ = tabBarController.viewControllers?[tabBarController.selectedIndex] as? UINavigationController, navController_.viewControllers.count <= 1 {
                            return  //Search tab first page
                        } else if tabBarController.selectedIndex == 4 {
                            return //Profile tab
                        }
                        if true == showBannerView {
                            let screenRect = UIScreen.main.bounds
                            let transparentView = TransparentView.init(frame: screenRect)
                            transparentView.tag = 90000 // TransparentView tag
                            transparentView.isFromOrderAnythingScreen = isFromOrderAnythingScreen
                            
                            let userDefaults = UserDefaults.standard
                            if let appOpenCloseStatusMessageString = userDefaults.object(forKey: appOpenCloseStatusMessage) as? String, 0 < appOpenCloseStatusMessageString.count {
                                transparentView.updateAppOpenCloseStatus(messageText: appOpenCloseStatusMessageString)
                            } else {
                                transparentView.updateAppOpenCloseStatus(messageText: "App closed now")
                            }
                            appDelegate.window?.addSubview(transparentView)
                            transparentView.backgroundColor = UIColor.clear
                            //                            transparentView.backgroundColor = (true == shouldShowTransparentBg) ?  UIColor.black.withAlphaComponent(0.5) : UIColor.clear
                        }
                    }
                }
            }
        }
    }
    
    func startTimerForAppOpenCloseState(appOpenCloseTime: Int? = -1) {
        cancelTimerForAppOpenCloseState()
        if -1 >= appOpenCloseTime ?? -1 {
            Utilities.removeTransparentView()
            return
        }
        appOpenCloseStateTimer = Timer.scheduledTimer(timeInterval: Double(appOpenCloseTime ?? 0)*60.0, target: self, selector: #selector(saveAppOpenCloseState), userInfo: nil, repeats: false)
        if let appOpenCloseStateTimer_ = appOpenCloseStateTimer {
            RunLoop.current.add(appOpenCloseStateTimer_, forMode: RunLoop.Mode.common)
        }
    }
    
    func cancelTimerForAppOpenCloseState() {
        if let timer_ = appOpenCloseStateTimer, timer_.isValid {
            appOpenCloseStateTimer?.invalidate()
        }
    }
    
    @objc func saveAppOpenCloseState() {
        // Call the callAppSettingsAPI and reschedule the timer for open or close state
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        appDelegate.callAppSettingsAPI()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: UpdateAppOpenCloseStatusNotification), object: nil)
    }
    
    func animateCartCountLabel() {
        guard let countView = Utilities.shared.cartView?.totalCartItemsLabel else { return }
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: countView.center.x - 3, y: countView.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: countView.center.x + 3, y: countView.center.y))
        
        countView.layer.add(animation, forKey: "position")
    }
    
}

extension String {
    func aesEncrypt(key: String, iv: String) throws -> String {
        if let data1 = data(using: .utf8) {
            let enc = try AES(key: key, iv: iv).encrypt(data1.bytes)
            let encData = Data(bytes: enc, count: enc.count)
            let base64String = encData.base64EncodedString()
            return base64String

//            if var keyBytes = key.data(using: .utf8)?.bytes, var ivBytes = iv.data(using: .utf8)?.bytes {
//                if 16 < keyBytes.count {
//                    // remove the extra bytes
//                } else {
//                    let diff = 16 - keyBytes.count
//                    for _ in 1...diff {
//                        keyBytes.append(0)
//                    }
//                }
//
//                if 16 < ivBytes.count {
//                    // remove the extra bytes
//                } else {
//                    let diff = 16 - ivBytes.count
//                    for _ in 1...diff {
//                        ivBytes.append(0)
//                    }
//                }
//
//                let enc = try AES(key: keyBytes, iv: ivBytes).encrypt(data1.bytes)
//                let encData = Data(bytes: enc, count: enc.count)
//                let base64String = encData.base64EncodedString()
//                return base64String
//            }
        }
        return ""
    }
    
    func aesDecrypt(key: String, iv: String) throws -> String {
        if let decData = Data(base64Encoded: self) {
            let dec = try AES(key: key, iv: iv).decrypt(decData.bytes)
            let decData1 = Data(bytes: dec, count: dec.count)
            let resultString = String(data: decData1, encoding: .utf8)
            return resultString ?? ""

//            if var keyBytes = key.data(using: .utf8)?.bytes, var ivBytes = iv.data(using: .utf8)?.bytes {
//                if 16 < keyBytes.count {
//                    // remove the extra bytes
//                } else {
//                    let diff = 16 - keyBytes.count
//                    for _ in 1...diff {
//                        keyBytes.append(0)
//                    }
//                }
//
//                if 16 < ivBytes.count {
//                    // remove the extra bytes
//                } else {
//                    let diff = 16 - ivBytes.count
//                    for _ in 1...diff {
//                        ivBytes.append(0)
//                    }
//                }
//
//                let dec = try AES(key: keyBytes, iv: ivBytes, blockMode: .CBC).decrypt(decData.bytes)
//                let decData1 = Data(bytes: dec, count: dec.count)
//                let resultString = String(data: decData1, encoding: .utf8)
//                return resultString ?? ""
//            } else {
//                return ""
//            }
        }
        return ""
    }
}
