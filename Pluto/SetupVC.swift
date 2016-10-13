//
//  SetupVC.swift
//  Pluto
//
//  Created by Faisal Lalani on 9/12/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import UIKit

class SetupVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    

 
    // MARK: - Button Actions
    
    @IBAction func goButtonAction(_ sender: AnyObject) {
        
        dismissKeyboard()
        
        if searchBar.text != nil {
            
            saveSchoolVoodoo(schoolName: searchBar.text! as String)

            // Switches to the board screen.
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "Board")
            self.present(vc!, animated: true, completion: nil)
        }
    }
    
    // MARK: - Firebase
    
    
    
    
    

    
    

    
    }
