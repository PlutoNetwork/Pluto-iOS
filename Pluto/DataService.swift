//
//  DataService.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/24/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Foundation
import Firebase

/// Contains the url of the database for Pluto. The Google-Service info.plist has it!
let DB_BASE = Database.database().reference()

/// Contains the url of the storage for Pluto. The Google-Service info.plist has it!
let STORAGE_BASE = Storage.storage().reference()

class DataService {
    
    /// A single instance of the data service.
    static let ds = DataService()
    
    /* Database references */
    private var _REF_BASE = DB_BASE
    private var _REF_EVENTS = DB_BASE.child("events")
    private var _REF_EVENT_LOCATIONS = DB_BASE.child("event_locations")
    private var _REF_USERS = DB_BASE.child("users")
    
    /* Storage references */
    private var _REF_EVENT_PICS = STORAGE_BASE.child("event-pics")
    private var _REF_PROFILE_PICS = STORAGE_BASE.child("profile-pics")
    
    var REF_BASE: DatabaseReference {
        
        return _REF_BASE
    }
    
    var REF_EVENTS: DatabaseReference {
        
        return _REF_EVENTS
    }
    
    var REF_EVENT_LOCATIONS: DatabaseReference {
        
        return _REF_EVENT_LOCATIONS
    }

    var REF_USERS: DatabaseReference {
        
        return _REF_USERS
    }
    
    var REF_CURRENT_USER: DatabaseReference {
        
        // Use user defaults to check if there's a user logged in.
        
        let userDefaults = UserDefaults.standard
        
        if (userDefaults.string(forKey: "email") != nil) {
            
            // If a user is logged in, create a Firebase reference to the user's data.
            
            let userID = Auth.auth().currentUser?.uid
            let user = REF_USERS.child(userID!)
            
            return user
        }
        
        return DatabaseReference()
    }
    
    var REF_CURRENT_USER_EVENTS: DatabaseReference {
        
        return REF_CURRENT_USER.child("events")
    }
        
    var REF_EVENT_PICS: StorageReference {
        
        return _REF_EVENT_PICS
    }
    
    var REF_PROFILE_PICS: StorageReference {
        
        return _REF_PROFILE_PICS
    }
    
    /**
     * Adds created users to the database (NOT authentication).
     
     - Parameter uid: the ID of the user being created.
     - Parameter userData: dictionary of data being stored (including email, board, provider, etc).
     */
    func createFirebaseDBUser(uid: String, userData: Dictionary<String, String>) {
    
        /* updateChildValues > setValue because setValue wipes out data instead of overwriting data. */
        
        REF_USERS.child(uid).updateChildValues(userData)
    }
}
