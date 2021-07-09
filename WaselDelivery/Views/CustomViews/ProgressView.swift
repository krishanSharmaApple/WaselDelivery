//
//  ProgressView.swift
//  WaselDelivery
//
//  Created by sunanda on 3/10/17.
//  Copyright © 2017 [x]cube Labs. All rights reserved.
//

import UIKit

class ProgressView: UIView, CAAnimationDelegate {

    private var progressLayer: CAShapeLayer!
    
    weak var delegate: AnimationDelegate?
    var progress: CGFloat = 0.0 {
        willSet(newValue) {
            
            let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")
            pathAnimation.duration = 0.25
            pathAnimation.fromValue = progress
            pathAnimation.autoreverses = false
            pathAnimation.delegate = self
            pathAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            pathAnimation.toValue = newValue
            pathAnimation.isRemovedOnCompletion = false
            pathAnimation.fillMode = CAMediaTimingFillMode.both
            progressLayer.add(pathAnimation, forKey: "drawCircle")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        let radius = frame.width / 2
        let progressPath = UIBezierPath(arcCenter: center, radius: radius - 1.0, startAngle: -.pi / 2, endAngle: 3 * (.pi / 2), clockwise: true)
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = 2.0
        backgroundLayer.strokeStart = 0.0
        backgroundLayer.strokeEnd = 1.0
        backgroundLayer.path = progressPath.cgPath
        backgroundLayer.strokeColor = UIColor.unSelectedBorderColor().cgColor
        layer.addSublayer(backgroundLayer)
        
        progressLayer = CAShapeLayer()
        progressLayer.frame = CGRect(x: 0.0, y: 0.0, width: bounds.width, height: bounds.height)
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 2.0
        progressLayer.strokeStart = 0.0
        progressLayer.strokeEnd = progress
        progressLayer.path = progressPath.cgPath
        progressLayer.strokeColor = UIColor.themeColor().cgColor
        layer.addSublayer(progressLayer)
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let delegate_ = delegate {
            delegate_.animationDidFinished(finished: flag)
        }
    }
    
}

protocol AnimationDelegate: class {
    func animationDidFinished(finished: Bool)
}
