//
//  TextView.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 1/11/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit

class TextView: UITextView {

    // MARK: - CONFIGURATION
    
    override func layoutSubviews() {
        
        setupView()
    }
    
    override func awakeFromNib() {
        
        setupView()
    }
    
    func setupView() {
        
        self.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }

}
