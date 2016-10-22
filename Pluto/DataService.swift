//
//  DataService.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/24/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Foundation
import Firebase

// MARK: - Global Variables

/// Contains the url of the database for Pluto. The Google-Service info.plist has it!
let DB_BASE = FIRDatabase.database().reference()

/// Contains the url of the storage for Pluto. The Google-Service info.plist has it!
let STORAGE_BASE = FIRStorage.storage().reference()

class DataService {
    
    /// A single instance of the data service.
    static let ds = DataService()
    
    // Globally accessible references
    
    // Database references
    private var _REF_BASE = DB_BASE
    private var _REF_BOARDS = DB_BASE.child("boards")
    private var _REF_USERS = DB_BASE.child("users")
    
    // Storage references
    private var _REF_EVENT_PICS = STORAGE_BASE.child("event-pics")
    private var _REF_PROFILE_PICS = STORAGE_BASE.child("profile-pics")
    
    var REF_BASE: FIRDatabaseReference {
        
        return _REF_BASE
    }
    
    var REF_BOARDS: FIRDatabaseReference {
        
        return _REF_BOARDS
    }

    var REF_USERS: FIRDatabaseReference {
        
        return _REF_USERS
    }
    
    var REF_CURRENT_USER: FIRDatabaseReference {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        let user = REF_USERS.child(userID!)
        
        return user
    }
        
    var REF_EVENT_PICS: FIRStorageReference {
        
        return _REF_EVENT_PICS
    }
    
    var REF_PROFILE_PICS: FIRStorageReference {
        
        return _REF_PROFILE_PICS
    }
    
    func createFirebaseDBUser(uid: String, userData: Dictionary<String, String>) {
    
        // Looks at users and creates a user if he/she doesn't already exist.
        // updateChildValues > setValue because setValue wipes out data instead of overwriting data.
        REF_USERS.child(uid).updateChildValues(userData)
    }
}
