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
import GoogleMaps
import GooglePlaces
    
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        /* Connect to Firebase when the app opens up. */
        
        FirebaseApp.configure()
        
        GMSServices.provideAPIKey("AIzaSyBjjIUQ2GeLbChnYSX22zXu3_l2zS52h_4")
        GMSPlacesClient.provideAPIKey("AIzaSyBjjIUQ2GeLbChnYSX22zXu3_l2zS52h_4")
                
        /// Grabs the email and password saved in a previous instance if the user already exists.
        let userDefaults = UserDefaults.standard
        
        /* Checks to see if there is an email saved in the userDefaults. */
        if userDefaults.string(forKey: "email") != nil {
            
            setRootViewController(identifier: "Main")
            
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

