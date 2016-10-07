//
//  Event.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/30/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Foundation

class Event {
    
    private var _board: String!
    private var _title: String!
    private var _time: String!
    private var _rocket: Bool!
    private var _eventKey: String!
    
    var board: String {
        
        return _board
    }
    
    var title: String {
        
        return _title
    }
    
    var time: String {
        
        return _time
    }
    
    var rocket: Bool {
        
        return _rocket
    }
    
    var eventKey: String {
        
        return _eventKey
    }
    
    init(board: String, title: String, time: String, rocket: Bool) {
        
        self._board = board
        self._title = title
        self._time = time
        self._rocket = rocket
    }
    
    init(eventKey: String, eventData: Dictionary<String, AnyObject>) {
        
        self._eventKey = eventKey
        
        // This data is received from Firebase.
        if let board = eventData["board"] as? String {
            
            self._board = board
        }
        
        if let title = eventData["title"] as? String {
            
            self._title = title
        }
        
        if let time = eventData["time"] as? String {
            
            self._time = time
        }
        
        if let rocket = eventData["rocket"] as? Bool {
            
            self._rocket = rocket
        }
    }
}
