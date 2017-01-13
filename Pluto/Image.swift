//
//  Image.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 1/12/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import Firebase

class Image {
    
    private var _imageKey: String!
    
    private var _creator: String!
    private var _imageURL: String!
    
    var imageKey: String {
        
        return _imageKey
    }
    
    var creator: String {
        
        return _creator
    }
    
    var imageURL: String {
        
        return _imageURL
    }
    
    init(creator: String, imageURL: String) {
        
        self._creator = creator
        self._imageURL = imageURL
    }
    
    init(imageKey: String, imageData: Dictionary<String, AnyObject>) {
        
        self._imageKey = imageKey
        
        if let creator = imageData["creator"] as? String {
            
            self._creator = creator
        }
        
        if let imageURL = imageData["URL"] as? String {
            
            self._imageURL = imageURL
        }
    }
}

