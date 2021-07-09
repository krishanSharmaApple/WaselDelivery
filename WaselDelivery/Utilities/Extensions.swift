//
//  Extensions.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 15/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

extension UIColor {
    
    static func themeColor() -> UIColor {
        return UIColor(red: 85.0/255.0, green: 190.0/255.0, blue: 109.0/255.0, alpha: 1.0)
    }

    static func unSelectedBorderColor() -> UIColor {
        return UIColor(red: (226.0/255.0), green: (226.0/255.0), blue: (226.0/255.0), alpha: 1.0)
    }

    static func selectedBorderColor() -> UIColor {
        return UIColor(red: (241.0/255.0), green: (90.0/255.0), blue: (42.0/255.0), alpha: 1.0)
    }

    static func unSelectedTextColor() -> UIColor {
        return UIColor(red: (152.0/255.0), green: (152.0/255.0), blue: (152.0/255.0), alpha: 1.0)
    }

    static func selectedTextColor() -> UIColor {
        return UIColor(red: (50.0/255.0), green: (50.0/255.0), blue: (50.0/255.0), alpha: 1.0)
    }

    static func feedbackColor() -> UIColor {
        return UIColor(red: (255.0/255.0), green: (236.0/255.0), blue: (51.0/255.0), alpha: 1.0)
    }

    static func alertColor() -> UIColor {
        return UIColor(red: (251.0/255.0), green: (44.0/255.0), blue: (44.0/255.0), alpha: 1.0)
    }

    static func unSelectedColor() -> UIColor {
        return UIColor(red: (157.0/255.0), green: (157.0/255.0), blue: (157.0/255.0), alpha: 1.0)
    }
    
    static func selectedColor() -> UIColor {
        return UIColor(red: (55.0/255.0), green: (55.0/255.0), blue: (55.0/255.0), alpha: 1.0)
    }
    
    static func orderCancelColor() -> UIColor {
        return UIColor(red: (255.0/255.0), green: (155.0/255.0), blue: (72.0/255.0), alpha: 1.0)
    }

    static func appBlack() -> UIColor {
        return UIColor(red: (53.0/255.0), green: (53.0/255.0), blue: (53.0/255.0), alpha: 1.0)
    }

}

extension String {
    
    var length: Int {
        return self.count
    }
    
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func random(length: Int = 20) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.length))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }
    
    func MD5() -> Data {
        let messageData = self.data(using: .utf8) ?? Data()
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData
    }

}

extension TimeZone {
    var minutesFromGMT: Int { return TimeZone.current.secondsFromGMT() / 60 }
}

extension UIImage {
    
    class func colorForNavBar(_ color: UIColor) -> UIImage {
        
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}

extension Bool {
    var intValue: Int {
        return self ? 1 : 0
    }
}

extension Int {
    func getDinams() -> Double {
        let amount = Double(self) / 1000
        let dinam = Double(round(1000 * amount) / 1000)
        return dinam
    }
}

extension Double {
    func getFills() -> Int {
        let fills = Int(self * 1000)
        return fills
    }

    var roundedToBD: Double {
        return (self * 1000).rounded() / 1000
    }
}

extension UIFont {
    
    class func montserratBlackWithSize(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Black", size: size) ?? UIFont()
    }

    class func montserratBoldWithSize(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Bold", size: size) ?? UIFont()
    }
    class func montserratExtraBoldWithSize(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-ExtraBold", size: size) ?? UIFont()
    }
    class func montserratExtraLightWithSize(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-ExtraLight", size: size) ?? UIFont()
    }
    class func montserratLightWithSize(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Light", size: size) ?? UIFont()
    }

    class func montserratMediumWithSize(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Medium", size: size) ?? UIFont()
    }
    class func montserratRegularWithSize(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Regular", size: size) ?? UIFont()
    }
    
    class func montserratSemiBoldWithSize(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-SemiBold", size: size) ?? UIFont()
    }
    
    class func montserratThinWithSize(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-Thin", size: size) ?? UIFont()
    }

}

extension UIViewController {
    
    class var storyboardID: String {
        return "\(self)"
    }
    
    static func instantiateFromStoryBoard(_ storyBoard: StoryBoard) -> Self {
        return storyBoard.viewController(viewControllerClass: self)
    }
    
    func registerForKeyboardDidShowNotification(_ constraint: NSLayoutConstraint, _ offset: CGFloat? = 0.0, shouldUseTabHeight: Bool? = true, usingBlock block: ((Notification) -> Void)? = nil) -> Any {
        
        return NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: nil, using: { (notification) -> Void in
            guard let userInfo = notification.userInfo else {
                return
            }
            guard let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else {
                return
            }
            if shouldUseTabHeight == true {
                constraint.constant = keyboardHeight - (offset ?? 0.0) - TabBarHeight
            } else {
                constraint.constant = keyboardHeight - (offset ?? 0.0)
            }
            
            block?(notification)
        })
    }
    
    func registerForKeyboardWillHideNotification(_ constraint: NSLayoutConstraint, _ offset: CGFloat? = 0.0, usingBlock block: ((Notification) -> Void)? = nil) -> Any {
        
        return NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil, using: { (notification) -> Void in
            constraint.constant = 0.0 + (offset ?? 0.0)
            block?(notification)
        })
    }
}

extension CAGradientLayer {
    
    func outletGradient() -> CAGradientLayer {
        
        let topColor = UIColor(red: (56.0/255.0), green: (56.0/255.0), blue: (56.0/255.0), alpha: 1)
        let bottomColor = UIColor(red: (0.0/255.0), green: (0.0/255.0), blue: (0.0/255.0), alpha: 1)
        
        let gradientColors: [CGColor] = [topColor.cgColor, bottomColor.cgColor]
        let gradientLocations: [NSNumber] = [NSNumber(value: 0), NSNumber(value: 1)]
        
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.locations = gradientLocations
        
        return gradientLayer
    }
}

extension Array where Element: Equatable {
    mutating func removeObject(object: Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
}

extension OutletItem: Equatable {
    static func == (lhs: OutletItem, rhs: OutletItem) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.price == rhs.price &&
            lhs.itemDescription == rhs.itemDescription &&
            lhs.imageUrl == rhs.imageUrl &&
            lhs.isVegItem == rhs.isVegItem &&
            lhs.isSpicy == rhs.isSpicy &&
            lhs.isActive == rhs.isActive &&
            lhs.isRecommended == rhs.isRecommended
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }

    func isBetweeen(date date1: Date, andDate date2: Date) -> Bool {
        return date1.compare(self).rawValue * self.compare(date2).rawValue >= 0
    }

    func replace(components: Set<Calendar.Component>, with date: Date) -> Date? {
        var calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        if let utcTimeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = utcTimeZone
        }
        var selfComponents = calendar.dateComponents(components, from: self)
        let targetComponents = calendar.dateComponents(components, from: date)
        for component in components {
            switch component {
            case .era: selfComponents.era = targetComponents.era
            case .year: selfComponents.year = targetComponents.year
            case .month: selfComponents.month = targetComponents.month
            case .day: selfComponents.day = targetComponents.day
            case .hour: selfComponents.hour = targetComponents.hour
            case .minute: selfComponents.minute = targetComponents.minute
            case .second: selfComponents.second = targetComponents.second
            case .weekday: selfComponents.weekday = targetComponents.weekday
            case .weekdayOrdinal: selfComponents.weekdayOrdinal = targetComponents.weekdayOrdinal
            case .quarter: selfComponents.quarter = targetComponents.quarter
            case .weekOfMonth: selfComponents.weekOfMonth = targetComponents.weekOfMonth
            case .weekOfYear: selfComponents.weekOfYear = targetComponents.weekOfYear
            case .yearForWeekOfYear: selfComponents.yearForWeekOfYear = targetComponents.yearForWeekOfYear
            case .nanosecond: selfComponents.nanosecond = targetComponents.nanosecond
            case .calendar: selfComponents.calendar = targetComponents.calendar
            case .timeZone: selfComponents.timeZone = targetComponents.timeZone
            }
        }
        return calendar.date(from: selfComponents)
    }
}

extension UIImage {
    
    func resizeImage(newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? UIImage()
    }
}

// MARK: - Get the top most visible viewcontroller

extension UIViewController {
    @objc func topMostViewController() -> UIViewController {
        // Handling Modal views
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topMostViewController()
        }
            // Handling UIViewController's added as subviews to some other views.
        else {
            for view in self.view.subviews {
                // Key property which most of us are unaware of / rarely use.
                if let subViewController = view.next {
                    if subViewController is UIViewController {
                        guard let viewController = subViewController as? UIViewController else {
                            return UIViewController()
                        }
                        return viewController.topMostViewController()
                    }
                }
            }
            return self
        }
    }
}

extension UITabBarController {
    override func topMostViewController() -> UIViewController {
        return self.selectedViewController?.topMostViewController() ?? UIViewController()
    }
}

extension UINavigationController {
    override func topMostViewController() -> UIViewController {
        return self.visibleViewController?.topMostViewController() ?? UIViewController()
    }
}

extension UITextView {
    
    /**
     Calculates if new textview height (based on content) is larger than a base height
     
     - parameter baseHeight: The base or minimum height
     
     - returns: The new height
     */
    func newHeight(withBaseHeight baseHeight: CGFloat) -> CGFloat {
        
        // Calculate the required size of the textview
        let fixedWidth = frame.size.width
        let newSize = sizeThatFits(CGSize(width: fixedWidth, height: .greatestFiniteMagnitude))
        var newFrame = frame
        
        // Height is always >= the base height, so calculate the possible new height
        let height: CGFloat = newSize.height > baseHeight ? newSize.height : baseHeight
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: height)
        
        return newFrame.height
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

extension UITextField{
    @IBInspectable var doneAccessory: Bool {
        get{
            return self.doneAccessory
        }
        set (hasDone) {
            if hasDone{
                addDoneButtonOnKeyboard()
            }
        }
    }

    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        self.inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction() {
        self.resignFirstResponder()
    }
}
