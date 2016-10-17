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

        /// Grabs the email and password saved in a previous instance if the user already exists.
        let userDefaults = UserDefaults.standard
        
        // Checks to see if there is an email saved in the userdefaults.
        if (userDefaults.string(forKey: "email") == nil) {
            
            // Switches to the login screen.
            self.tabBarController?.selectedIndex = 1
            
        } else {
            
            // There is a user logged in.
            
            // Sets the first tab that shows to whatever we put in the storyboard attributes for the controller.
            selectedIndex = defaultIndex
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        print("CLICKED")
        return true
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        // Checks to see if user clicks on logout button.
        if item.tag == 0 {
            
            // Create an alert to ask the user if a new account should be created.
            let notice = SCLAlertView()
            
            notice.addButton("Yes!") {
                
                // The user wishes to log out.
                // Switches to the login screen.
                self.tabBarController?.selectedIndex = 1
            }
            
            notice.showInfo("Hey!", subTitle: "You have opted to logout. Continue?", closeButtonTitle: "No, I made a mistake!")
            
            
        }
    }
}
