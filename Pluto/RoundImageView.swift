//
//  RoundImageView.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/2/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit

class RoundImageView: UIImageView {

    override func awakeFromNib() {
        
        self.layer.masksToBounds = true
        self.layer.borderWidth = 3.0
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }
}
