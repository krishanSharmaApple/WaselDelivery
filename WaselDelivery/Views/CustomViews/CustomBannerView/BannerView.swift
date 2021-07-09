//
//  BannerView.swift
//  WaselDelivery
//
//  Created by PurpleTalk on 05/06/18.
//  Copyright © 2018 PurpleTalk. All rights reserved.
//

import UIKit

class BannerView: UIView {

    @IBOutlet private weak var messageButton: UIButton!
    private let toastHeight: CGFloat = 80.0
    private let toastDuration: Int = 10
    var notificationInfo: [AnyHashable: Any]?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addView()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(pangestureMethod))
        panGesture.translation(in: self)
        self.addGestureRecognizer(panGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func pangestureMethod() {
        self.removeFromSuperview()
    }
    
    func showNotification(notificationInformation: [AnyHashable: Any]) {
        if let apsDict = notificationInformation["aps"] as? [String: Any] {
            if let alertInfo = apsDict["alert"] as? [String: Any] {
                if let message = alertInfo["body"] as? String {
                    notificationInfo = notificationInformation
                    self.updateBannerMessage(message: message)
                    self.showMessage()
                }
            }
        }
    }

    func showMessage() {
        let windows = UIApplication.shared.windows
        let lastWindow = windows.last
        lastWindow?.addSubview(self)
        
        self.frame = CGRect(x: 0, y: -self.toastHeight, width: self.frame.size.width, height: self.frame.size.height)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: self.toastHeight)
        }, completion: {(_: Bool) -> Void in
            let dispatchTime = DispatchTime.now() + .seconds(self.toastDuration)
            DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
                self.close()
            }
        })
    }
    
    func close() {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.frame = CGRect(x: 0, y: -self.toastHeight, width: self.frame.size.width, height: self.frame.size.height)
        }, completion: {(_: Bool) -> Void in
            self.removeFromSuperview()
        })
    }

// MARK: - User defined methods
    
    private func addView() {
        let nib = UINib(nibName: "BannerView", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView ?? UIView()
        view.frame = self.frame
        self.addSubview(view)
    }
    
    private func updateBannerMessage(message: String) {
        messageButton.setTitle(message, for: .normal)
    }
    
// MARK: - Button Actions
    
    @IBAction func messageButtonAction(sender: AnyObject) {
        self.removeFromSuperview()
        if let notificationInfo_ = notificationInfo {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.handleUpshotDeepLinkAction(userData: notificationInfo_)
        }
    }
    
}
