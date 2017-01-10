//
//  AnimationEngine.swift
//  Pluto
//
//  Created by Faisal Lalani on 9/11/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit
import pop

class AnimationEngine {
    
    /// The center of the screen.
    class var centerPosition: CGPoint {
    
        return CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
    }
    
    /// A horizontally centered position above and off the screen.
    class var offScreenTopPosition: CGPoint {
        
        return CGPoint(x: UIScreen.main.bounds.midX, y: -UIScreen.main.bounds.height)
    }
    
    class func animateToPosition(view: UIView, position: CGPoint) {
        
        let moveAnim = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
        moveAnim?.toValue = NSValue(cgPoint: position)
        moveAnim?.springBounciness = 0.2
        moveAnim?.springSpeed = 0.2
        view.pop_add(moveAnim, forKey: "moveToPosition")
    }
    
    class func fadeAnimation(view: UIView, duration: Double, alpha: CGFloat) {
        
        UIView.animate(withDuration: duration) { 
            
            view.alpha = alpha
        }
    }
}
