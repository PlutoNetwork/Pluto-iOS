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
    private var _email: String!
    private var _board: String!
    private var _provider: String!
    private var _image: String!
    private var _connected: Bool!
    private var _request: Bool!
    private var _friendKey: String!
    
    var name: String! {
        
        return _name
    }
    
    var email: String! {
        
        return _email
    }
    
    var board: String! {
        
        return _board
    }
    
    var provider: String! {
        
        return _provider
    }
    
    var image: String! {
        
        return _image
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
    
    init(name: String, email: String, board: String, provider: String, image: String, connected: Bool, request: Bool) {
        
        self._name = name
        self._email = email
        self._board = board
        self._provider = provider
        self._image = image
        self._connected = connected
        self._request = request
    }
    
    init(friendKey: String, friendData: Dictionary<String, AnyObject>) {
        
        self._friendKey = friendKey
        
        if let name = friendData["name"] as? String {
            
            self._name = name
        }
        
        if let email = friendData["email"] as? String {
            
            self._email = email
        }
        
        if let board = friendData["board"] as? String {
            
            self._board = board
        }
        
        if let provider = friendData["provider"] as? String {
            
            self._provider = provider
        }
        
        if let image = friendData["image"] as? String {
            
            self._image = image
        }
        
        if let connected = friendData["connected"] as? Bool {
            
            self._connected = connected
        }
        
        if let request = friendData["request"] as? Bool {
            
            self._request = request
        }
    }
}
