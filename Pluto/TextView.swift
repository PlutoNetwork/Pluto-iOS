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
    
    override func awakeFromNib() {
        
        self.textContainerInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    }

}
