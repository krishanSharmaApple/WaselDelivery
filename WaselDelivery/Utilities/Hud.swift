//
//  Hud.swift
//  WaselDelivery
//
//  Created by Purpletalk on 11/7/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import Foundation
import UIKit

class Hud {
    
    static let shared = Hud()
    private var loadingImageView: UIImageView?
    private var backgroundView: UIView?
    
    private init() {
        
    }
    
    func showHUD(to view: UIView?, _ message: String?) {
        guard let `view` = view else {
            return
        }
//        guard loadingImageView == nil else {
//            return
//        }

        if nil != loadingImageView {
            self.hideHUD()
        }
        
        UIApplication.shared.beginIgnoringInteractionEvents()

        // Add background transperant View. Used to disable User interactions in it's parentView
        backgroundView = UIView(frame: view.bounds)
        backgroundView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView?.backgroundColor = .clear
        backgroundView?.isUserInteractionEnabled = true
        if let bgView = backgroundView {
            view.addSubview(bgView)
        }

        loadingImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 70.0, height: 70.0))
        if let imageView = loadingImageView {
            imageView.tag = 1901
            imageView.backgroundColor = UIColor.clear
            var images = [UIImage]()
            
            for index in 1...120 {
                let imageName =  String(format: "loading%03d", index)
                images.append(UIImage(named: imageName) ?? UIImage())
            }
            
            imageView.animationImages = images
            imageView.animationDuration = 2.6
            imageView.center = view.center
            view.addSubview(imageView)
            imageView.startAnimating()
            
//            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let windowObj = appDelegate.window {
//                windowObj.addSubview(imageView)
//                imageView.center = windowObj.center
//                imageView.startAnimating()
//            }
        }
    }
    
    func hideHUD() {
        loadingImageView?.removeFromSuperview()
        loadingImageView = nil
        backgroundView?.removeFromSuperview()
        backgroundView = nil
        UIApplication.shared.endIgnoringInteractionEvents()
    }

}
