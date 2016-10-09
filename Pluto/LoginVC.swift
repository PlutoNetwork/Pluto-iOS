//
//  ViewController.swift
//  Pluto
//
//  Created by Faisal Lalani on 9/11/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import FirebaseAuth
import pop
import UIKit

class LoginVC: UIViewController, UITextFieldDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var goButton: Button!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    // MARK: - View Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController?.tabBar.layer.isHidden = true
        
        // Dismisses the keyboard if the user taps anywhere on the screen.
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginVC.dismissKeyboard)))
        
        // Sets the text field delegates accordingly.
        emailField.delegate = self
        passwordField.delegate = self
    }

    // MARK: - Actions
    
    @IBAction func goButtonAction(_ sender: AnyObject) {
        
        dismissKeyboard()
        firebaseLoginSignupVoodoo(email: emailField.text!, password: passwordField.text!)
    }
    
    // MARK: - Firebase
    
    /**
     
     Saves the user to the database.
     
     */
    func saveToDatabaseVoodoo(user: FIRUser?, userID: String, email: String, providerID: String) {
        
        // Makes sure the user exists first.
        if let user = user {
            
            // Creates a dictionary that will be saved to the database.
            let userData = ["provider": providerID,
                            "email": email]
            
            DataService.ds.createFirebaseDBUser(uid: user.uid, userData: userData)
        }
    }
    
    /**
     
     Logs the user in if successful; creates an account if user is not found in database.
     
     */
    func firebaseLoginSignupVoodoo(email: String, password: String) {
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            
            if error == nil {
                
                // Success! The user has logged in!
                
                self.saveUser(user: user!, userID: (user?.uid)!, email: email, password: password, providerID: (user?.providerID)!)
                self.tabBarController?.selectedIndex = 3
                
            } else {
                
                // Error!
                
                print((error.debugDescription))
                
                if error?._code == STATUS_ACCOUNT_NONEXIST {
                    
                    // The user doesn't exist! Creating account now...
                    
                    FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                        
                        if error != nil {
                         
                            // Error!
                            print((error?._code))
                            
                        } else {
                            
                            // Success! The user has been created!
                            
                            self.saveUser(user: user!, userID: (user?.uid)!, email: email, password: password, providerID: (user?.providerID)!)
                            self.transition(transitionTo: "Setup")
                        }
                    })
                }
            }
        })
    }
    
    // MARK: - Helpers
    
    func dismissKeyboard() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    /**
     
     Saves the user's email and password to NSUserDefaults to bypass login for future use.
     
     */
    func saveDefault(email: String, password: String) {
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(email, forKey: "email")
        userDefaults.set(password, forKey: "password")
    }
    
    func saveUser(user: FIRUser?, userID: String?, email: String, password: String, providerID: String) {
        
        saveToDatabaseVoodoo(user: user, userID: userID!, email: email, providerID: providerID)
        saveDefault(email: email, password: password)
    }
    
    /**
     
     Function that allows transition to any other screen.
     
     */
    func transition(transitionTo: String) {

        // Switches to the setup screen.
        let vc = self.storyboard?.instantiateViewController(withIdentifier: transitionTo)
        self.present(vc!, animated: true, completion: nil)
    }
    
    // MARK: - Text Field Functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard.
        textField.resignFirstResponder()
        return true
    }
}

