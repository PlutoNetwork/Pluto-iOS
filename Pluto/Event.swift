//
//  Event.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/30/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase

class Event {
    
    private var _eventRef: FIRDatabaseReference!
    
    private var _eventKey: String!
    
    private var _board: String!
    private var _count: Int!
    private var _creator: String!
    private var _description: String!
    private var _imageURL: String!
    private var _location: String!
    private var _time: String!
    private var _title: String!
    
    var eventKey: String {
        
        return _eventKey
    }
    
    var board: String {
        
        return _board
    }
    
    var count: Int {
        
        return _count
    }
    
    var creator: String {
        
        return _creator
    }
    
    var description: String {
        
        return _description
    }
    
    var imageURL: String {
        
        return _imageURL
    }
    
    var location: String {
        
        return _location
    }
    
    var time: String {
        
        return _time
    }
    
    var title: String {
        
        return _title
    }
    
    init(board: String, count: Int, creator: String, description: String, imageURL: String, location: String, time: String, title: String) {
        
        self._board = board
        self._count = count
        self._creator = creator
        self._description = description
        self._imageURL = imageURL
        self._location = location
        self._time = time
        self._title = title
    }
    
    init(eventKey: String, eventData: Dictionary<String, AnyObject>) {
        
        self._eventKey = eventKey
        
        if let board = eventData["board"] as? String {
            
            self._board = board
        }
        
        if let count = eventData["count"] as? Int {
            
            self._count = count
        }
        
        if let creator = eventData["creator"] as? String {
            
            self._creator = creator
        }
        
        if let description = eventData["description"] as? String {
            
            self._description = description
        }
        
        if let imageURL = eventData["imageURL"] as? String {
            
            self._imageURL = imageURL
        }
        
        if let location = eventData["location"] as? String {
            
            self._location = location
        }
        
        if let time = eventData["time"] as? String {
            
            self._time = time
        }
        
        if let title = eventData["title"] as? String {
            
            self._title = title
        }
        
        _eventRef = DataService.ds.REF_CURRENT_BOARD.child("events").child(_eventKey)
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
