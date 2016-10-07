//
//  ProfileVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class ProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Outlets
    
    // Text fields
    
    @IBOutlet weak var nameField: TextField!
    @IBOutlet weak var emailField: TextField!
    
    // Buttons
    
    @IBOutlet weak var saveButton: Button!
    
    // MARK: - Variables
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateIfGiven()

    }
    
    // MARK: - Button Actions


    @IBAction func saveButtonAction(_ sender: AnyObject) {
        
        // Switches to the profile screen.
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Main")
        self.present(vc!, animated: true, completion: nil)
    }
    
    // MARK: - Firebase
    
    /**
     
     If the user already has a set value (like name or picture) from before, this loads it in.
 
    */
    func updateIfGiven() {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        DataService.ds.REF_USERS.child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            
            let value = snapshot.value as? NSDictionary
            
            if value?["name"] != nil {
                
                self.nameField.text = value?["name"] as? String
                
            }
            
            if value?["email"] != nil {
                
                self.emailField.text = value?["email"] as? String
            }
            
        }) { (error) in
            
            // Error!
            
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Helpers
    
}
