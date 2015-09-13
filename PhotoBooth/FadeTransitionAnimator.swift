//
//  FadeTransitionAnimator.swift
//  PhotoBooth
//
//  Created by Ben Jones on 10/27/14.
//  Copyright (c) 2014 Ben D. Jones. All rights reserved.
//

import Foundation
import UIKit

class FadeTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var isDismiss: Bool = false

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.38
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        var toView: UIView?
        var fromView: UIView?
        
        if let view = transitionContext.viewForKey(UITransitionContextToViewKey) {
            toView = view
        } else {
            toView = UIView()
        }
        
        if let view = transitionContext.viewForKey(UITransitionContextFromViewKey) {
            fromView = view
        } else {
            fromView = UIView()
        }

        toView?.alpha = isDismiss ? 1 : 0
        
        guard let containerView = transitionContext.containerView() else { return }
        containerView.addSubview(fromView!)
        containerView.addSubview(toView!)
        
        toView?.tintAdjustmentMode = .Dimmed
        fromView?.tintAdjustmentMode = .Dimmed
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, options: .CurveEaseOut, animations: {
            fromView?.alpha = 0
            
            toView?.alpha = 1
            toView?.tintAdjustmentMode = .Automatic
        }) { finished in
            fromView?.alpha = 1
            fromView?.tintAdjustmentMode = .Automatic
            
            let transitionCanceled = transitionContext.transitionWasCancelled()
            transitionContext.completeTransition(!transitionCanceled)
        }
    }
}