//
//  UserInfo.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/24/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import Foundation

class UserInfo {
    
    func grabUserInfo() {
        
        DataService.ds.REF_CURRENT_USER.observe(.value, with: { (snapshot) in
            
            
            
        })
    }
}
