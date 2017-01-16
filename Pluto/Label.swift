//
//  Label.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 1/15/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit

class Label: UILabel {

    // MARK: - CONFIGURATION
    
    override func awakeFromNib() {
        
        /* Shadow properties. */
        layer.shadowColor = SHADOW_COLOR.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 6.0
        layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
    }
}
