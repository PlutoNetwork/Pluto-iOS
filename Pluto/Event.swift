//
//  Event.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/30/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Foundation

class Event {
    
    private var _title: String!
    private var _eventKey: String!
    
    var title: String {
        
        return _title
    }

    var eventKey: String {
        
        return _eventKey
    }
    
    init(title: String) {
        
        self._title = title
    }
    
    init(eventKey: String, eventData: Dictionary<String, AnyObject>) {
        
        self._eventKey = eventKey
        
        // This data is received from Firebase.
        if let title = eventData["title"] as? String {
            
            self._title = title
        }
    }
}
