//
//  Friend.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/20/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit

class User {
    
    private var _name: String!
    private var _connected: Bool!
    private var _request: Bool!
    private var _friendKey: String!
    
    var name: String! {
        
        return _name
    }
    
    var connected: Bool {
        
        return _connected
    }
    
    var request: Bool {
        
        return _request
    }
    
    var friendKey: String {
        
        return _friendKey
    }
    
    init(name: String, connected: Bool, request: Bool) {
        
        self._name = name
        self._connected = connected
        self._request = request
    }
    
    init(friendKey: String, friendData: Dictionary<String, AnyObject>) {
        
        self._friendKey = friendKey
        
        if let name = friendData["name"] as? String {
            
            self._name = name
        }
        
        if let connected = friendData["connected"] as? Bool {
            
            self._connected = connected
        }
        
        if let request = friendData["request"] as? Bool {
            
            self._request = request
        }
    }
}
