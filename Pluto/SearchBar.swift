//
//  SearchBox.swift
//  Pluto
//
//  Created by Faisal Lalani on 9/15/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit

@IBDesignable
class SearchBar : UISearchBar {
    
    @IBInspectable var inset: CGFloat = 0
    
    override func awakeFromNib() {
        
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        setupView()
    }
    
    func setupView() {
        
        
    }
    
}
