//
//  TabBarC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/16/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit

class TabBarC: UITabBarController, UITabBarControllerDelegate {

    // MARK: - Variables
    
    /// Allows the option to edit the first tab that shows in the storyboard.
    @IBInspectable var defaultIndex: Int = 0
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedIndex = defaultIndex
    }
}
