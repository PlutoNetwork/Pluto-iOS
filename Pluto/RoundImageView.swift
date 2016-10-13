//
//  RoundImageView.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit

class RoundImageView: UIImageView {
    
    override func layoutSubviews() {
        
        layer.cornerRadius = self.frame.width / 2
        clipsToBounds = true
    }
}
