//
//  Board.swift
//  Pluto
//
//  Created by Faisal Lalani on 9/14/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Foundation

class Board {
    
    private var _title: String!
    private var _boardKey: String!
    
    var title: String {
        
        return _title
    }
    
    var boardKey: String {
        
        return _boardKey
    }
    
    init(title: String) {
        
        self._title = title
    }
    
    init(boardKey: String, boardData: Dictionary<String, AnyObject>) {
        
        self._boardKey = boardKey
        
        // This data is received from Firebase.
        if let title = boardData["title"] as? String {
            
            self._title = title
        }
    }
}
