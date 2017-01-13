//
//  CameraButton.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 1/13/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import pop

@IBDesignable
class CameraButton: UIButton {
    
    // MARK: - CONFIGURATION
    
    override func awakeFromNib() {
        
        setupView()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        setupView()
    }
    
    /**
     *  Sets default properties to the view.
     */
    func setupView() {
        
        /* Shadow properties */
        layer.shadowColor = SHADOW_COLOR.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 6.0
        layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
        /* Adds a pulse animation when the button is tapped. */
        self.addTarget(self, action: #selector(Button.scaleToSmall), for: .touchDown)
        self.addTarget(self, action: #selector(Button.scaleToSmall), for: .touchDragEnter)
        self.addTarget(self, action: #selector(Button.scaleAnimation), for: .touchUpInside)
        self.addTarget(self, action: #selector(Button.scaleDefault), for: .touchDragExit)
    }
    
    // MARK: - ANIMATION
    
    /**
     *  #PULSE
     *
     *  Makes the button smaller.
     */
    func scaleToSmall() {
        
        let scaleAnim = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnim?.toValue = NSValue(cgSize: CGSize(width: 0.95, height: 0.95))
        self.layer.pop_add(scaleAnim, forKey: "layerScaleToSmallAnimation")
    }
    
    /**
     *  #PULSE
     *
     *  Makes the button bigger.
     */
    func scaleAnimation() {
        
        let scaleAnim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnim?.velocity = NSValue(cgSize: CGSize(width: 3.0, height: 3.0))
        scaleAnim?.toValue = NSValue(cgSize: CGSize(width: 1.0, height: 1.0))
        scaleAnim?.springBounciness = 18
        self.layer.pop_add(scaleAnim, forKey: "layerScaleSpringAnimation")
    }
    
    /**
     *  #PULSE
     *
     *  Brings the button back down to normal size.
     */
    func scaleDefault() {
        
        let scaleAnim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnim?.toValue = NSValue(cgSize: CGSize(width: 1.0, height: 1.0))
        self.layer.pop_add(scaleAnim, forKey: "layerScaleDefaultAnimation")
    }
}

