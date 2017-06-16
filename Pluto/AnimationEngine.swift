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
    
    /// A horizontally centered position to the right of the screen.
    class var offScreenRightPosition: CGPoint {
        
        return CGPoint(x: UIScreen.main.bounds.width + 1000, y: UIScreen.main.bounds.midY)
    }
    
    /// A horizontally centered position to the left of the screen.
    class var offScreenLeftPosition: CGPoint {
        
        return CGPoint(x: UIScreen.main.bounds.width - 1000, y: UIScreen.main.bounds.midY)
    }
    
    /**
      Animates a passed-in view to a passed-in position.
     
     - Parameter view: the view to animate.
     - Parameter position: the position to animate to.
     */
    class func animateToPosition(view: UIView, position: CGPoint) {
        
        let moveAnim = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
        moveAnim?.toValue = NSValue(cgPoint: position)
        moveAnim?.springBounciness = 0.2
        moveAnim?.springSpeed = 5
        view.pop_add(moveAnim, forKey: "moveToPosition")
    }
}
