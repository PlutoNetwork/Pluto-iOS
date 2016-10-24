//
//  SquareImageView.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/23/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit

class SquareImageView: UIImageView {

    override func layoutSubviews() {
        
        clipsToBounds = true
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.white.cgColor
    }
}
