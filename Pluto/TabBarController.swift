//
//  TabbarController.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 1/10/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    // MARK: - PROPERTIES
    
    /// Allows the option to edit the first tab that shows in the storyboard.
    @IBInspectable var defaultIndex: Int = 0
    
    // MARK: - VIEW
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedIndex = defaultIndex
    }
}
