//
//  EventView.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/8/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit

class EventView: UIView {
    
    override func awakeFromNib() {
        
        layer.cornerRadius = 5.0
        layer.shadowColor = SHADOW_COLOR.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 6.0
        layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
    }    
}
