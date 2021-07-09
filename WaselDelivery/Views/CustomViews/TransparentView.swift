//
//  TransparentView.swift
//  WaselDelivery
//
//  Created by Purpletalk on 7/11/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class TransparentView: UIView {
    
    @IBOutlet weak var appOpenCloseStatusLabel: UILabel!
    @IBOutlet weak var statusLabelTopConstraint: NSLayoutConstraint!
    var isFromOrderAnythingScreen = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.xibSetup()
    }
    
    fileprivate func xibSetup() {
        let view: UIView = loadViewFromNib()
        view.frame = bounds
        
        let statusBarFrame: CGRect = UIApplication.shared.statusBarFrame
        let yPos: CGFloat = (true == isFromOrderAnythingScreen) ? 58.0 : 55.0
        let topPosition = (yPos + (20.0 >= statusBarFrame.size.height ? 0.0 : (statusBarFrame.size.height - 20.0)))
        statusLabelTopConstraint.constant = topPosition

        addSubview(view)
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let nib = UINib(nibName: "TransparentView", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView ?? UIView()
        return view
    }
    
    func updateAppOpenCloseStatus(messageText: String) {
        appOpenCloseStatusLabel.text = messageText
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}
