//
//  Event.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/30/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase

class Event {
    
    private var _title: String!
    private var _location: String!
    private var _time: String!
    private var _description: String!
    private var _creator: String!
    private var _pluto: Bool!
    private var _count: Int!
    private var _imageURL: String!
    private var _eventKey: String!
    private var _eventRef: FIRDatabaseReference!
    
    var title: String {
        
        return _title
    }
    
    var location: String {
        
        return _location
    }
    
    var time: String {
        
        return _time
    }
    
    var description: String {
        
        return _description
    }
    
    var creator: String {
        
        return _creator
    }
    
    var count: Int {
        
        return _count
    }
    
    var imageURL: String {
        
        return _imageURL
    }

    var eventKey: String {
        
        return _eventKey
    }
    
    init(title: String, location: String, time: String, description: String, creator: String, count: Int, imageURL: String) {
        
        self._title = title
        self._location = location
        self._time = time
        self._description = description
        self._creator = creator
        self._count = count
        self._imageURL = imageURL
    }
    
    init(eventKey: String, eventData: Dictionary<String, AnyObject>) {
        
        self._eventKey = eventKey
        
        // This data is received from Firebase.
        if let title = eventData["title"] as? String {
            
            self._title = title
        }
        if let location = eventData["location"] as? String {
            
            self._location = location
        }
        if let time = eventData["time"] as? String {
            
            self._time = time
        }
        if let description = eventData["description"] as? String {
            
            self._description = description
        }
        if let creator = eventData["creator"] as? String {
            
            self._creator = creator
        }
        if let count = eventData["count"] as? Int {
            
            self._count = count
        }
        if let imageURL = eventData["imageURL"] as? String {
            
            self._imageURL = imageURL
        }
        
        let userDefaults = UserDefaults.standard
        
        _eventRef = DataService.ds.REF_BOARDS.child(userDefaults.string(forKey: "board")!).child("events").child(_eventKey)
    }
    
    func adjustCount(addToCount: Bool) {
        
        if addToCount {
            
            _count = _count + 1
            
        } else {
            
            _count = _count - 1
        }
        
        _eventRef.child("count").setValue(_count)
    }
}
