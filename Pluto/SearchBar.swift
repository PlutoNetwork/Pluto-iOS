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
    
    // MARK: - PROPERTIES
    
    @IBInspectable var inset: CGFloat = 0
    
    // MARK: - CONFIGURATION
    
    override func awakeFromNib() {
        
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setupView()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        setupView()
    }
    
    func setupView() {
        
        self.tintColor = UIColor.white
        
        self.barStyle = .black
        self.backgroundColor = UIColor.black
        self.barTintColor = UIColor.black
        
        /* Add a shadow to the search bar. */
        
        self.layer.shadowColor = SHADOW_COLOR.cgColor
        self.layer.shadowOpacity = 0.5
        self.layer.masksToBounds = false
        
        self.searchBarStyle = .prominent
        
        setupText()
    }
    
    func setupText() {
        
        /* Changes the font and font size for text inside the search bar. */
        let textFieldInsideUISearchBar = self.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont(name: "Lato-Regular", size: 18)
        textFieldInsideUISearchBar?.textColor = UIColor.gray
        
        /* This does the same thing as above but this is for the placeholder text. */
        let textFieldInsideUISearchBarLabel = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideUISearchBarLabel?.font = UIFont(name: "Lato-Regular", size: 18)
        textFieldInsideUISearchBarLabel?.textColor = UIColor.white
    }
}
