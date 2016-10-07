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
    
    // Buttons
    @IBOutlet weak var goButton: Button!
    
    // Constraints
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailFieldTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordFieldTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var goButtonTopConstraint: NSLayoutConstraint!
    
    // Labels
    @IBOutlet weak var titleLabel: UILabel!
    
    // Text Fields
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    // MARK: - Variables
    
    // MARK: - View Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dismisses the keyboard if the user taps anywhere on the screen.
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginVC.dismissKeyboard)))
        
        // Sets the text field delegates accordingly.
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func goButtonAction(_ sender: AnyObject) {
        
        dismissKeyboard()
        firebaseLoginSignupVoodoo()
    }
    
    // MARK: - Firebase
    
    func completeFirebaseVoodoo(user: FIRUser?, userID: String, email: String, providerID: String) {
                
        if let user = user {
            
            let userData = ["provider": providerID,
                            "email": email]
            
            DataService.ds.createFirebaseDBUser(uid: user.uid, userData: userData)
            
        }
    }
    
    /**
     
     Logs the user in if successful; creates an account if user is not found in database.
     
     */
    func firebaseLoginSignupVoodoo() {
        
        if let email = emailField.text, let password = passwordField.text {
            
            FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                
                if error == nil {
                    
                    // Success! The user has logged in!
                    
                    self.completeFirebaseVoodoo(user: user!, userID: (user?.uid)!, email: email, providerID: (user?.providerID)!)
                    
                } else {
                    
                    // Error!
                    
                    print("ERROR: Unable to sign in - \(error)")
                    
                    if error?._code == STATUS_ACCOUNT_NONEXIST {
                        
                        // The user doesn't exist! Creating account now...
                        
                        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                            
                            if error != nil {
                             
                                // Error!
                                
                                print("ERROR: Unable to authenticate with Firebase - \(error)")
                                
                            } else {
                                
                                // Success! The user has been created!
                                
                                self.completeFirebaseVoodoo(user: user!, userID: (user?.uid)!, email: email, providerID: (user?.providerID)!)
                                
                            }
                        })
                    }
                }
            })
        }
    }
    
    // MARK: - Helpers
    
    func transitionToSetup() {

        // Switches to the setup screen.
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Setup")
        self.present(vc!, animated: true, completion: nil)
    }
    
    func dismissKeyboard() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    // MARK: - Text Field Functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard.
        textField.resignFirstResponder()
        return true
    }
}

