    //
//  AppDelegate.swift
//  Pluto
//
//  Created by Faisal Lalani on 9/11/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit
import CoreData
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FIRApp.configure()
        
        /* Navigation bar customization */
    
        // let latoFont = UIFont(name: "Lato-Regular", size: 14.0)
        
        // UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: latoFont!, NSForegroundColorAttributeName: UIColor.white] // Changes the title font, font size, and color.
        
        /// Grabs the email and password saved in a previous instance if the user already exists.
        let userDefaults = UserDefaults.standard
        
        /* Checks to see if there is an email saved in the userDefaults. */
        if userDefaults.string(forKey: "email") != nil {
            
            if userDefaults.string(forKey: "boardKey") != nil {
                
                /* Bypass to the main board screen. */
                setRootViewController(identifier: "Main")
                
            } else {
                
                setRootViewController(identifier: "Search")
            }
            
        } else {
        
            setRootViewController(identifier: "Login")
        }
        
        return true
    }
    
    // MARK: - HELPERS
    
    /**
     *  Changes the initial view controller based on if the user is logged in or not.
     */
    func setRootViewController(identifier: String) {
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        self.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: identifier)
        
        self.window?.makeKeyAndVisible()
    }
}

