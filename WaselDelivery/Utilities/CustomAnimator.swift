//
//  CustomAnimator.swift
//  WaselDelivery
//
//  Created by Purpletalk on 20/03/18.
//  Copyright © 2018 [x]cube Labs. All rights reserved.
//

import UIKit

class CustomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var duration: TimeInterval
    var isPresenting: Bool
    var originalRect: CGRect
    
    init(duration: TimeInterval, isPresenting: Bool, originalRect: CGRect) {
        self.duration = duration
        self.isPresenting = isPresenting
        self.originalRect = originalRect
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        
        guard let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to) else {
            return
        }
        
        isPresenting ? container.addSubview(toView) : container.insertSubview(toView, belowSubview: fromView)
        
        let detailView = isPresenting ? toView : fromView
        toView.frame = isPresenting ? originalRect : toView.frame
        toView.layoutIfNeeded()
        
        UIView.animate(withDuration: duration, animations: {
            detailView.frame = self.isPresenting ? fromView.frame:  self.originalRect
        }, completion: { (completed) in
            guard completed else { return }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
