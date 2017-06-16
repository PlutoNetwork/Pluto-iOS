//
//  Event.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/30/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase

class Event {
    
    private var _eventRef: DatabaseReference!
    
    private var _eventKey: String!
    
    private var _count: Int!
    private var _creator: String!
    private var _imageURL: String!
    private var _timeStart: String!
    private var _timeEnd: String!
    private var _title: String!
    
    var eventKey: String {
        
        return _eventKey
    }
    
    var count: Int {
        
        return _count
    }
    
    var creator: String {
        
        return _creator
    }
    
    var imageURL: String {
        
        return _imageURL
    }
    
    var timeStart: String {
        
        return _timeStart
    }
    
    var timeEnd: String {
        
        return _timeEnd
    }
    
    var title: String {
        
        return _title
    }
    
    init(count: Int, creator: String, imageURL: String, timeStart: String, timeEnd: String, title: String) {
        
        self._count = count
        self._creator = creator
        self._imageURL = imageURL
        self._timeStart = timeStart
        self._timeEnd = timeEnd
        self._title = title
    }
    
    init(eventKey: String, eventData: Dictionary<String, AnyObject>) {
        
        self._eventKey = eventKey
        
        if let count = eventData["count"] as? Int {
            
            self._count = count
        }
        
        if let creator = eventData["creator"] as? String {
            
            self._creator = creator
        }
        
        if let imageURL = eventData["imageURL"] as? String {
            
            self._imageURL = imageURL
        }
        
        if let timeStart = eventData["timeStart"] as? String {
            
            self._timeStart = timeStart
        }
        
        if let timeEnd = eventData["timeEnd"] as? String {
            
            self._timeEnd = timeEnd
        }
        
        if let title = eventData["title"] as? String {
            
            self._title = title
        }
        
        _eventRef = DataService.ds.REF_EVENTS.child(_eventKey)
    }
    
    /**
      Adjusts the count of the number of the people going to the event.
     
     - Parameter addToCount: a flag that indicates whether the user is going to an event or not anymore.
     */
    func adjustCount(addToCount: Bool) {
        
        if addToCount {
            
            _count = _count + 1
            
        } else {
            
            _count = _count - 1
        }
        
        _eventRef.child("count").setValue(_count)
    }
}
