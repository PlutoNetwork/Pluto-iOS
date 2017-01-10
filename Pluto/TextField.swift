//
//  TextField.swift
//  Pluto
//
//  Created by Faisal Lalani on 9/11/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit

@IBDesignable
class TextField : UITextField {
    
    // MARK: - PROPERTIES
    
    @IBInspectable var inset: CGFloat = 0 // The space between the edge and the text.
    
    /* The following functions set the inset. */
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        
        return bounds.insetBy(dx: inset, dy: inset)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        
        return textRect(forBounds: bounds)
    }
    
    @IBInspectable var placeholderTextColor: UIColor? {
        get {
            
            return self.placeholderTextColor
        } set {
            
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSForegroundColorAttributeName: newValue!])
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        /* Draws a line underneath the text field */
        
        let startingPoint = CGPoint(x: rect.minX, y: rect.maxY)
        let endingPoint = CGPoint(x: rect.maxX, y: rect.maxY)
        
        let path = UIBezierPath()
        
        path.move(to: startingPoint)
        path.addLine(to: endingPoint)
        path.lineWidth = 2.0
        
        tintColor = UIColor.white
        tintColor.setStroke()
        
        path.stroke()
    }
}
