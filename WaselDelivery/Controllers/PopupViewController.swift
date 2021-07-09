//
//  PopupViewController.swift
//  WaselDelivery
//
//  Created by Amarnath Reddy on 30/09/16.
//  Copyright © 2016 [x]cube Labs. All rights reserved.
//

import UIKit
import Foundation

class PopupViewController: UIViewController {
    
    var containerView: UIView!
    var alertBackgroundView: UIView!
    var dismissButton: UIButton!
    var cancelButton: UIButton!
    var buttonLabel: UILabel!
    var cancelButtonLabel: UILabel!
    var textView: UITextView!
    var titleLabel: UILabel!
    weak var rootViewController: UIViewController!
    var iconImage: UIImage!
    var iconImageView: UIImageView!
    var closeAction: (() -> Void)!
    var cancelAction: (() -> Void)!
    var isAlertOpen: Bool = false
    var noButtons: Bool = false
    var optionalButton: UIButton!
    var optionalText: UILabel!
    var optionalBtnAction: (() -> Void)!
    
//    var titleFont = "HelveticaNeue-Light"
//    var textFont = "HelveticaNeue"
//    var buttonFont = "Lato-Bold"
    var isOptionalBtnSelected: Bool = false
    
    enum ActionType {
        case close, cancel
    }
    
    let baseHeight: CGFloat = 160.0
    var alertWidth: CGFloat = 290.0
    let buttonHeight: CGFloat = 40.0
    let padding: CGFloat = 20.0
    
    var viewWidth: CGFloat?
    var viewHeight: CGFloat?
    
//    weak var delegate: OptionalButtonProtocol?
    
    // Allow alerts to be closed/renamed in a chainable manner
    class AlertViewResponder {
        let alertview: PopupViewController
        
        init(alertview: PopupViewController) {
            self.alertview = alertview
        }
        
        func addAction(_ action: @escaping () -> Void) {
            self.alertview.addAction(action)
        }
        
        func addCancelAction(_ action: @escaping () -> Void) {
            self.alertview.addCancelAction(action)
        }
        
        func setDismissButtonColor(_ color: UIColor) {
            self.alertview.dismissButton.backgroundColor = color
        }
        
        func setCancelButtonColor(_ color: UIColor) {
            self.alertview.cancelButton.backgroundColor = color
        }

        func setCancelTitleColor(_ color: UIColor) {
            self.alertview.cancelButton.setTitleColor(color, for: .normal)
        }

        func setCancelButtonBorderColor(_ color: UIColor) {
            self.alertview.cancelButton.layer.borderWidth = 1.0
            self.alertview.cancelButton.layer.borderColor = color.cgColor
        }

        func setDismissButtonBorderColor(_ color: UIColor) {
            self.alertview.cancelButton.layer.borderWidth = 1.0
            self.alertview.dismissButton.layer.borderColor = color.cgColor
        }

        func setDismissTitleColor(_ color: UIColor) {
            self.alertview.dismissButton.setTitleColor(color, for: .normal)
        }

        func setButtoncolor(_ color: UIColor) {
            self.alertview.cancelButton.backgroundColor = color
            self.alertview.dismissButton.backgroundColor = color
        }
        
        @objc func close() {
            self.alertview.closeView(false)
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let size = self.rootViewControllerSize()
        self.viewWidth = size.width
        self.viewHeight = size.height
        
        var yPos: CGFloat = 0.0
        let contentWidth: CGFloat = self.alertWidth - (self.padding*2)
        
        // position the icon image view, if there is one
        //        if self.iconImageView != nil {
        //            yPos += iconImageView.frame.height
        //            let centerX = (self.alertWidth-self.iconImageView.frame.width)/2
        //            self.iconImageView.frame.origin = CGPoint(x: centerX, y: self.padding)
        //            yPos += padding
        //        }
        
        yPos = 25
        
        if self.titleLabel != nil {
            self.titleLabel.frame = CGRect(x: self.padding, y: yPos, width: self.alertWidth - (self.padding*2), height: 30)
            textView.textAlignment = .center
            yPos += 30
        }
        
        // position text
        if self.textView != nil {
            let textString = textView.text as NSString
            let textAttr = [NSAttributedString.Key.font: textView.font as AnyObject]
            let realSize = textView.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
            let textSize = CGSize(width: contentWidth, height: CGFloat(fmaxf(Float(90.0), Float(realSize.height))))
            let textRect = textString.boundingRect(with: textSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: textAttr, context: nil)
            self.textView.frame = CGRect(x: self.padding, y: yPos, width: self.alertWidth - (self.padding*2), height: ceil(textRect.size.height)*2)
            yPos += ceil(textRect.size.height) + padding/2
        }
        
        // size the background view
        self.alertBackgroundView.frame = CGRect(x: 0, y: 0, width: self.alertWidth, height: yPos)

        // position the buttons
        
        if self.noButtons == false {
            yPos += self.padding + 10
            
            if self.dismissButton != nil {
                self.dismissButton.frame = CGRect(x: self.alertWidth/2 - 110, y: yPos, width: 100, height: self.buttonHeight)
                self.dismissButton.layer.cornerRadius = 4.0
                self.dismissButton.layer.borderWidth = 1.0
                self.dismissButton.layer.borderColor = UIColor(red: 226.0/255, green: 226.0/255, blue: 226.0/255, alpha: 1.0).cgColor
            }
            
            // let buttonX = buttonWidth == self.alertWidth ? 35 : buttonWidth + 30
            if self.cancelButton != nil {
                self.cancelButton.frame = CGRect(x: self.alertWidth/2 + 10, y: yPos, width: 100, height: self.buttonHeight)
//                self.cancelButton.layer.borderColor = UIColor(red: 226.0/255, green: 226.0/255, blue: 226.0/255, alpha: 1.0).cgColor
//                self.cancelButton.layer.borderWidth = 1.0
                self.cancelButton.layer.cornerRadius = 4.0
                if self.dismissButton == nil {
                    var aCenter = self.cancelButton.center
                    aCenter.x = alertBackgroundView.center.x
                    self.cancelButton.center = aCenter
                }
            } else {
                var aCenter = self.dismissButton.center
                aCenter.x = alertBackgroundView.center.x
                self.dismissButton.center = aCenter
            }
            
            yPos += self.buttonHeight
        } else {
            yPos += self.padding
        }
        // size the background view
        self.alertBackgroundView.frame = CGRect(x: 0, y: 0, width: self.alertWidth, height: yPos+25)
        
        // size the container that holds everything together
        if let viewWidth_ = self.viewWidth, let viewHeight_ = self.viewHeight {
            self.containerView.frame = CGRect(x: (viewWidth_ - self.alertWidth)/2, y: (viewHeight_ - yPos)/2, width: self.alertWidth, height: yPos+25)
        }
    }
    
    func showAlert(viewcontroller viewController: UIViewController, title: String?, text: String? = nil, buttonText: String? = nil, cancelButtonText: String? = nil, attText: NSAttributedString? = nil) -> AlertViewResponder {
        
        self.rootViewController = viewController
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        let textColor = UIColor(red: 152.0/255, green: 152.0/255, blue: 152.0/255, alpha: 1.0)
        
        let sz = self.screenSize()
        self.viewWidth = sz.width
        self.viewHeight = sz.height
        self.view.frame.size = sz
        
        // Container for the entire alert modal contents
        self.containerView = UIView()
        if nil != self.containerView {
            self.view.addSubview(self.containerView)
        }
        
        // Background view/main color
        self.alertBackgroundView = UIView()
        alertBackgroundView.backgroundColor = UIColor.white
        alertBackgroundView.layer.cornerRadius = 0
        alertBackgroundView.layer.masksToBounds = true
        if nil != self.alertBackgroundView {
            self.containerView.addSubview(self.alertBackgroundView)
        }
        
        if let title = title {
            if title.count > 0 {
                self.titleLabel = UILabel()
                self.titleLabel.textColor = UIColor.black
                self.titleLabel.textAlignment = .center
                self.titleLabel.font = UIFont.montserratRegularWithSize(20.0)
                self.titleLabel.backgroundColor = UIColor.clear
                self.titleLabel.text = title
                self.containerView.addSubview(self.titleLabel)
            }
        }
        
        // View text
        self.textView = UITextView()
        self.textView.isUserInteractionEnabled = false
        textView.isEditable = false
        textView.textColor = textColor
        textView.textAlignment = .left
        textView.font = UIFont.montserratRegularWithSize(16.0)
        textView.backgroundColor = UIColor.clear

        if let text = text {
            if let attText_ = attText {
                textView.attributedText = attText_
            } else {
                textView.text = text
            }
            self.containerView.addSubview(textView)
        } else if let attText_ = attText {
            textView.attributedText = attText_
            self.containerView.addSubview(textView)
        }
        
        if buttonText != nil {
            self.dismissButton = UIButton()
            dismissButton.addTarget(self, action: #selector(PopupViewController.buttonTap), for: .touchUpInside)
            dismissButton.setTitleColor(.unSelectedTextColor(), for: .normal)
            dismissButton.titleLabel?.textAlignment = .center
            if let text = buttonText {
                dismissButton.setTitle(text, for: .normal)
            } else {
                dismissButton.setTitle("OK", for: .normal)
            }
            dismissButton.titleLabel?.font = UIFont.montserratBoldWithSize(16.0)
            
            self.dismissButton.backgroundColor = .white
            if nil != alertBackgroundView {
                alertBackgroundView.addSubview(dismissButton)
            }
        }
        
        // Second cancel button
        if cancelButtonText != nil {
            self.cancelButton = UIButton()
            cancelButton.addTarget(self, action: #selector(PopupViewController.cancelButtonTap), for: .touchUpInside)
            cancelButton.titleLabel?.textColor =  .white
            cancelButton.titleLabel?.textAlignment = .center
            cancelButton.setTitle(cancelButtonText, for: .normal)
            cancelButton.titleLabel?.font = UIFont.montserratBoldWithSize(16.0)
            cancelButton.setTitleColor(UIColor.white, for: .normal)
            self.cancelButton.backgroundColor = .alertColor()
            if nil != alertBackgroundView {
                alertBackgroundView.addSubview(cancelButton)
            }
        }
        
        // Animate it in
        self.view.alpha = 0
        self.definesPresentationContext = true
        self.modalPresentationStyle = .overFullScreen
        viewController.present(self, animated: false, completion: {
            // Animate it in
            UIView.animate(withDuration: 0.0, animations: {
                self.view.alpha = 1
            })
            
            self.containerView.center.x = self.view.center.x
            self.containerView.center.y = -500
            
            UIView.animate(withDuration: 0.0, delay: 0.00, usingSpringWithDamping: 0.0, initialSpringVelocity: 0.0, options: [], animations: {
                self.containerView.center = self.view.center
                }, completion: { _ in
                    self.isAlertOpen = true
//                    self.closeView(true)
//                    if let d = delay {
//                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(d * Double(NSEC_PER_SEC)))
//                        dispatch_after(delayTime, dispatch_get_main_queue()) {
//                            self.closeView(true)
//                        }
//                    }
            })
        })
        
        return AlertViewResponder(alertview: self)
    }
    
    func addAction(_ action: @escaping () -> Void) {
        self.closeAction = action
    }
    
    @objc func buttonTap() {
        closeView(true, source: .close)
    }
    
    func addCancelAction(_ action: @escaping () -> Void) {
        self.cancelAction = action
    }
    
    @objc func cancelButtonTap() {
        closeView(true, source: .cancel)
    }
    
    func addOptionalAction(_ action: @escaping () -> Void) {
        self.optionalBtnAction = action
    }
    
    /*  func optionalBtnTap(sender: UIButton) {
     if sender.selected == true {
     sender.selected = false
     sender.tintColor = UIColor.tuyaGrayColor()
     self.isOptionalBtnSelected = false
     }else {
     sender.selected = true
     sender.tintColor = UIColor.tuyaGreenColor()
     self.isOptionalBtnSelected = true
     }
     }*/
    
    func closeView(_ withCallback: Bool, source: ActionType = .close) {
        UIView.animate(withDuration: 0.0, delay: 0, usingSpringWithDamping: 0.0, initialSpringVelocity: 0.0, options: [], animations: {
            if let viewHeight_ = self.viewHeight {
                self.containerView.center.y = self.view.center.y + viewHeight_
            }
            }, completion: { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    self.view.alpha = 0
                    }, completion: { _ in
                        self.dismiss(animated: false, completion: {
                            
                            if withCallback {
                                if let action = self.closeAction, source == .close {
                                    action()
                                } else if let action = self.cancelAction, source == .cancel {
                                    action()
                                }
                            }
                        })
                })
        })
    }
    
    func removeView() {
        isAlertOpen = false
        self.removeFromParent()
        self.view.removeFromSuperview()
    }
    
    func rootViewControllerSize() -> CGSize {
        let size = self.rootViewController.view.frame.size
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) && UIApplication.shared.statusBarOrientation.isLandscape {
            return CGSize(width: size.height, height: size.width)
        }
        return size
    }
    
    func screenSize() -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) && UIApplication.shared.statusBarOrientation.isLandscape {
            return CGSize(width: screenSize.height, height: screenSize.width)
        }
        return screenSize
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let locationPoint = touch.location(in: self.view)
            let converted = self.containerView.convert(locationPoint, from: self.view)
            if self.containerView.point(inside: converted, with: event) {
                if self.noButtons == true {
                    closeView(true, source: .cancel)
                }
            }
        }
    }
}
