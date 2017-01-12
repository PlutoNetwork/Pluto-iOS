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
let DB_BASE = FIRDatabase.database().reference()

/// Contains the url of the storage for Pluto. The Google-Service info.plist has it!
let STORAGE_BASE = FIRStorage.storage().reference()

class DataService {
    
    /// A single instance of the data service.
    static let ds = DataService()
    
    /* Database references */
    private var _REF_BASE = DB_BASE
    private var _REF_BOARDS = DB_BASE.child("boards")
    private var _REF_EVENTS = DB_BASE.child("events")
    private var _REF_USERS = DB_BASE.child("users")
    
    /* Storage references */
    private var _REF_EVENT_PICS = STORAGE_BASE.child("event-pics")
    private var _REF_PROFILE_PICS = STORAGE_BASE.child("profile-pics")
    
    var REF_BASE: FIRDatabaseReference {
        
        return _REF_BASE
    }
    
    var REF_BOARDS: FIRDatabaseReference {
        
        return _REF_BOARDS
    }
    
    var REF_EVENTS: FIRDatabaseReference {
        
        return _REF_EVENTS
    }

    var REF_USERS: FIRDatabaseReference {
        
        return _REF_USERS
    }
    
    var REF_CURRENT_BOARD: FIRDatabaseReference {
        
        let userDefaults = UserDefaults.standard
        
        if (userDefaults.string(forKey: "boardKey") != nil) {
            
            let boardKey = userDefaults.string(forKey: "boardKey")
            let board = REF_BOARDS.child(boardKey!)
            
            return board
        }
        
        return FIRDatabaseReference()
    }
    
    var REF_CURRENT_BOARD_EVENTS: FIRDatabaseReference {
        
        return REF_CURRENT_BOARD.child("events")
    }
    
    var REF_CURRENT_USER: FIRDatabaseReference {
        
        let userDefaults = UserDefaults.standard
        
        if (userDefaults.string(forKey: "email") != nil) {
            
            let userID = FIRAuth.auth()?.currentUser?.uid
            let user = REF_USERS.child(userID!)
            
            return user
        }
        
        return FIRDatabaseReference()
    }
    
    var REF_CURRENT_USER_EVENTS: FIRDatabaseReference {
        
        return REF_CURRENT_USER.child("events")
    }
        
    var REF_EVENT_PICS: FIRStorageReference {
        
        return _REF_EVENT_PICS
    }
    
    var REF_PROFILE_PICS: FIRStorageReference {
        
        return _REF_PROFILE_PICS
    }
    
    /**
     * Adds created users to the database (NOT authentication).
     *
     * - Parameter uid: The ID of the user being created.
     * - Parameter userData: Dictionary of data being stored (including email, board, provider, etc).
     */
    func createFirebaseDBUser(uid: String, userData: Dictionary<String, String>) {
    
        /* updateChildValues > setValue because setValue wipes out data instead of overwriting data. */
        
        REF_USERS.child(uid).updateChildValues(userData)
    }
}
