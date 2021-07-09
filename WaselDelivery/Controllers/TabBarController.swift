//
//  TabBarController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 15/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    var centerButton: UIButton!
    var centerView: UIView?
    var centerImageView: UIImageView!
    var centerLabel: UILabel!
    
    var shouldHideTabCenterButton = false {
        didSet {
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }

// MARK: - View LifeCycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.delegate = self
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        tabBar.layer.shadowColor = UIColor.gray.cgColor
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -1.0)
        tabBar.layer.shadowOpacity = 0.2
        tabBar.layer.shadowRadius = 2.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if centerView == nil, let orderAnythingImageView = UIImage(named: "orderAnything") {
            addCenterViewWithImage(image: orderAnythingImageView)
        }
    }

    override func viewWillLayoutSubviews() {        
        let tabFrame: CGRect = self.tabBar.frame
        self.tabBar.frame = CGRect(x: 0.0, y: tabFrame.origin.y, width: tabFrame.size.width, height: tabFrame.size.height)

        let tabWidth = ScreenWidth / 5
        if shouldHideTabCenterButton == true {
            
            var aCenter = tabBar.center
            aCenter.x = (aCenter.x - (1.5 * tabWidth))
            UIView.animate(withDuration: 0.25, animations: {
                self.centerView?.center = aCenter
                self.centerView?.alpha = 0.0
            })
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.centerView?.center = self.tabBar.center
                self.centerView?.alpha = 1.0
                self.tabBar.isHidden = false
                if let centerView_ = self.centerView {
                    self.view.bringSubviewToFront(centerView_)
                }
            })
        }
    }
        
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if 4 != tabBarController.selectedIndex { //4 for profile tab
            Utilities.showTransparentView()
        } else {
            Utilities.removeTransparentView()
        }
        
        if 3 == tabBarController.selectedIndex { //3 Order history tab
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: RefreshOrderHistoryNotification), object: nil, userInfo: nil)
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if centerButton?.isSelected == true {
            if let navController = viewControllers?[2] as? UINavigationController {
                if let controller =  navController.viewControllers.last as? OrderAnythingController {
                    if controller.specialOrder.didEditedOrder() {
                        let popupVC = PopupViewController()
                        let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "When you leave this place cart will be cleared. Do you want to clear?", buttonText: "Cancel", cancelButtonText: "Clear")
                        responder.addCancelAction({
                            DispatchQueue.main.async(execute: {
                                controller.clearOrder()
                                self.deselectOrderAnythingButton()
                                self.selectedViewController = viewController
                            })
                        })
                        return false
                    } else {
                        deselectOrderAnythingButton()
                    }
                }
            }
        } else {
            if Utilities.shared.cart.cartItems.count > 0 {
                
                let popupVC = PopupViewController()
                let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "Your order will be lost because you can only order from one shop at a time.", buttonText: "Cancel", cancelButtonText: "Clear")
                responder.addCancelAction({
                    DispatchQueue.main.async(execute: {
                        // send event to UPSHOT before clearing cart
                        let params = ["CartID": Utilities.shared.cartId ?? ""]
                        UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CLEAR_CART_EVENT, params: params)

                        Utilities.shared.clearCart()
                        self.deselectOrderAnythingButton()
                        self.selectedViewController = viewController
                    })
                })
                return false
            } else {
                deselectOrderAnythingButton()
            }
        }
        return true
    }
    
// MARK: - CenterView Methods
    
    func addCenterViewWithImage(image: UIImage) {
        
        let buttonWidth = UIScreen.main.bounds.width / 5
        let imageWidth: CGFloat = 40.0
        let imageHeight: CGFloat = 40.0
        let tabBarHeight = self.tabBar.bounds.height
        let aHeight: CGFloat = (true == Utilities.shared.isIphoneX()) ? 50.0 : 21.0

        centerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: buttonWidth, height: tabBarHeight + aHeight))
        centerView?.center = tabBar.center
        if let centerView_ = centerView {
            view.addSubview(centerView_)
            
            centerImageView = UIImageView(image: image)
            let imageX = centerView_.frame.width / 2 - imageWidth / 2
            centerImageView.frame = CGRect(x: imageX, y: 0.0, width: imageWidth, height: imageHeight)
            centerView_.addSubview(centerImageView)
            
            let labelY = centerImageView.frame.height + 4.0
            let labelHeight: CGFloat = 8.0
            centerLabel = UILabel(frame: CGRect(x: 0.0, y: labelY, width: centerView_.frame.width, height: labelHeight))
            
            centerLabel.font = UIFont.montserratRegularWithSize(8.0)
            centerLabel.textColor = .unSelectedTextColor()
            centerLabel.numberOfLines = 1
            centerLabel.textAlignment = .center
            centerLabel.text = "Order Anything"
            centerView_.addSubview(centerLabel)
            
            centerButton = UIButton(frame: centerView_.bounds)
            centerButton.setTitle("", for: .normal)
            centerButton.backgroundColor = .clear
            centerButton.addTarget(self, action: #selector(centerButtonClicked), for: .touchUpInside)
            centerView_.addSubview(centerButton)
        }
    }
    
    @objc func centerButtonClicked(sender: UIButton) {
        if let centerButton_ = centerButton {
            if !centerButton_.isSelected {
                if Utilities.shared.cart.cartItems.count > 0 {
                    
                    let popupVC = PopupViewController()
                    let responder = popupVC.showAlert(viewcontroller: self, title: "Wasel Delivery", text: "Your order will be lost because you can only order from one shop at a time.", buttonText: "Cancel", cancelButtonText: "Clear")
                    responder.addCancelAction({
                        DispatchQueue.main.async(execute: {
                            Utilities.shared.clearCart()
                            UPSHOTActivitySetup.shared.createCustomEvent(eventName: BKConstants.CLEAR_CART_EVENT)
                            if self.selectedIndex == 3 {
                                let nav = self.viewControllers?[3] as? UINavigationController
                                _ = nav?.popToRootViewController(animated: false)
                            }
                            self.selectOrderAnythingButton()
                        })
                    })
                    responder.addAction({
                        DispatchQueue.main.async(execute: {
                            self.deselectOrderAnythingButton()
                        })
                    })
                } else {
                    self.selectOrderAnythingButton()
                }
            }
        }
    }
    
    private func selectOrderAnythingButton() {
        centerButton?.isSelected = true
        self.selectedIndex = 2
        centerImageView.image = UIImage(named: "orderAnything_active")
        centerLabel.textColor = .selectedTextColor()

        // create cartId if not exist
        if Utilities.shared.cartId == nil {
            Utilities.shared.cartId = UUID().uuidString
        }
    }
    
    private func deselectOrderAnythingButton() {
        centerButton?.isSelected = false
        centerImageView.image = UIImage(named: "orderAnything")
        centerLabel.textColor = .unSelectedTextColor()

        // remove cart id
        Utilities.shared.cartId = nil
    }
    
}

class WaselTabBar: UITabBar {
    var oldSafeAreaInsets = UIEdgeInsets.zero
    
    override func safeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.safeAreaInsetsDidChange()
            if oldSafeAreaInsets != safeAreaInsets {
                oldSafeAreaInsets = safeAreaInsets
                invalidateIntrinsicContentSize()
                superview?.setNeedsLayout()
                superview?.layoutSubviews()
            }
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        if #available(iOS 11.0, *) {
            let bottomInset = safeAreaInsets.bottom
            if bottomInset > 0 && size.height < 50 && (size.height + bottomInset < 90) {
                size.height += bottomInset
            }
        }
        return size
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        } set {
            var tmp = newValue
            if let superview = superview, tmp.maxY != superview.frame.height {
                tmp.origin.y = superview.frame.height - tmp.height
            }
            super.frame = tmp
        }
    }
}
