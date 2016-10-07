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
    
    class var centerPosition: CGPoint {
    
        return CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
    }
    
    class var offScreenBottomPosition: CGPoint {
        
        return CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.height)
    }
    
    var originalConstants = [CGFloat]()
    var constraints: [NSLayoutConstraint]!
    
    init(constraints: [NSLayoutConstraint]) {
        
        for con in constraints {
            
            originalConstants.append(con.constant)
            con.constant = AnimationEngine.offScreenBottomPosition.y
        }
        
        self.constraints = constraints
    }
    
    func animateOnScreen() {
        
        var index = 0
        
        repeat {
            
            let moveAnim = POPSpringAnimation(propertyNamed: kPOPLayoutConstraintConstant)
            moveAnim?.toValue = self.originalConstants[index]
            moveAnim?.springBounciness = 7
            moveAnim?.springSpeed = 15
            
            let con = self.constraints[index]
            
            con.pop_add(moveAnim, forKey: "moveOnScreen")
            
            index += 1
            
        } while (index < self.constraints.count)
    }
    
    class func animateToPosition(view: UIView, position: CGPoint) {
        
        let moveAnim = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
        moveAnim?.toValue = NSValue(cgPoint: position)
        moveAnim?.springBounciness = 3
        moveAnim?.springSpeed = 5
        view.pop_add(moveAnim, forKey: "moveToPosition")
        
    }
}
