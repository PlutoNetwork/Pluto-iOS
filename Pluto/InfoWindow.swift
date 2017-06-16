//
//  InfoWindow.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/5/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit

class InfoWindow: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        setupView()
    }
    
    override func awakeFromNib() {
                
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setupView()
    }
    
    func setupView() {
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 10.0
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.shadowColor = SHADOW_COLOR.cgColor
        self.setNeedsLayout()
    }
}
