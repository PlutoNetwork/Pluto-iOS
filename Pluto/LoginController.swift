//
//  ViewController.swift
//  Pluto
//
//  Created by Faisal Lalani on 9/11/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import pop

class LoginController: UIViewController {
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var goButton: Button!
    
    // MARK: - VIEW
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Initializes the text fields. */
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    // MARK: - BUTTONS
    
    @IBAction func goButtonAction(_ sender: AnyObject) {
        
        dismissKeyboard()
        firebaseLoginSignupVoodoo(email: emailField.text!, password: passwordField.text!)
    }
    
    // MARK: - Firebase
    
    /**
     *  #AUTHENTICATION
     *
     *  Firebase authorization checks to see if the user has an account by trying to recognize the emai
     *  and password. If it isn't found, an error will tell us that there is no account with those
     *  credentials. An account will then be created.
     *
     *  - Parameter email: The email from the emailField.text (provided by the user).
     *  - Parameter password: The password from the passwordField.text (provided by the user).
     *
     *  - Todo: Create alerts to notify the user what *specific* error occurs.
     */
    func firebaseLoginSignupVoodoo(email: String, password: String) {
        
        /// Create an alert to show errors.
        let notice = SCLAlertView()
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            
            if error == nil {
                
                /* SUCCESS: The user has logged in. */
                
                self.saveDefault(email: email, password: password)
                
                self.clearFields()
                
                self.switchController(controllerID: "Main") // Transitions to the main board screen.
                
            } else {
                
                /* ERROR: Something went wrong with logging in. */
                
                switch (error?._code)! {
                    
                case STATUS_ACCOUNT_NONEXIST:
                    
                    /* Firebase couldn't match the credentials of the account to an existing one, so a new account is created *after* the user is asked if an account should be created. */
                    
                    notice.addButton("Yes!") {
                        
                        /* The user has given permission to create him/her an account. */

                        /* Firebase does some voodoo to create the user an account with the provided information. */
                        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                            
                            if error != nil {
                                
                                /* ERROR: Something went wrong creating an account. */
                                
                                SCLAlertView().showError("Oh no!", subTitle: "Pluto could not create an account for you at this time.")
                                
                            } else {
                                
                                /* SUCCESS: The user has been created. */
                                
                                self.saveUser(user: user!, userID: (user?.uid)!, email: email, password: password, providerID: (user?.providerID)!)
                                
                                self.performSegue(withIdentifier: "showSearch", sender: self) // Transitions to the search screen.
                            }
                        })
                    }
                    
                    notice.showInfo("Hey!", subTitle: "Pluto couldn't find an account with these credentials. Should we create you a new account?", closeButtonTitle: "No, I made a mistake!")
                    
                case STATUS_PASSWORD_INCORRECT:
                    
                    /* The user typed in his/her password incorrectly. */
                    
                    notice.showError("Oh no!", subTitle: "You typed your password incorrectly. Try again!")
                    
                case STATUS_FIELDS_BLANK:
                    
                    /* The user left one or both fields blank. */
                    
                    notice.showError("Oh no!", subTitle: "You left a field blank! Make sure to fill them BOTH out.")
                    
                default:
                    
                    /* Something went wrong that wasn't caught above. */
                    
                    notice.showError("Oh no!", subTitle: "Something went wrong. Try again!")
                }
            }
        })
    }
        
    /**
     *  #AUTHENTICATION
     *
     *  Saves the user to the Firebase database.
     *
     *  - Parameter user: The user that was created by Firebase and successfully authorized.
     *  - Parameter userID: The user's unique ID.
     *  - Parameter email: The user's email inputted in the emailField.text.
     *  - Parameter providerID: How the user signed up (Firebase, Facebook, Google, etc.).
     */
    func saveToDatabaseVoodoo(user: FIRUser?, userID: String, email: String, providerID: String) {
        
        if let user = user {
            
            /// Creates a dictionary for the user information that will be saved to the database.
            let userData = ["provider": providerID,
                            "image": "https://firebasestorage.googleapis.com/v0/b/pluto-b5a22.appspot.com/o/profile-pics%2F1E667F17-6982-4136-903A-0BCF71C1CD55?alt=media&token=05b32815-8e85-4593-a129-f3eb8bb300f6",
                            "name": email,
                            "email": email]
            
            /* The default image is just a random one from the storage. */
            
            DataService.ds.createFirebaseDBUser(uid: user.uid, userData: userData)
        }
    }
    
    // MARK: - HELPERS
    
    /**
     *  Clears the text fields.
     */
    func clearFields() {
        
        emailField.text = ""
        passwordField.text = ""
    }
    
    /**
     *  Dismisses the keyboard.
     *  Just put whatever textfields you want included here in the function.
     */
    func dismissKeyboard() {
        
        /* Dismisses the keyboard for these text fields. */
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    /**
     *  #USER-DEFAULTS
     *
     *  Saves the user's email and password to NSUserDefaults to bypass login for future use.
     *
     *  - Parameter email: The email from the emailField.text (provided by the user).
     *  - Parameter password: The password from the passwordField.text (provided by the user).
     */
    func saveDefault(email: String, password: String) {
                
        let userDefaults = UserDefaults.standard
        
        /* Save the email and password into userDefaults. */
        userDefaults.set(email, forKey: "email")
        userDefaults.set(password, forKey: "password")
    }
    
    /**
     *  #GATEWAY
     *
     *  Avoids repetitive function calling when saving the user.
     *
     *  - Parameter user: The user that was created by Firebase and successfully authorized.
     *  - Parameter userID: The user's unique ID.
     *  - Parameter email: The user's email inputted in the emailField.text.
     *  - Parameter password: The user's password inputted in the passwordField.text.
     *  - Parameter providerID: How the user signed up (Firebase, Facebook, Google, etc.).
     */
    func saveUser(user: FIRUser?, userID: String?, email: String, password: String, providerID: String) {
        
        saveToDatabaseVoodoo(user: user, userID: userID!, email: email, providerID: providerID)
        saveDefault(email: email, password: password)
    }
    
    /**
     *  #TRANSITION
     *
     *  Switches to the view controller specified by the parameter.
     *  Use to avoid navigation controller, which allows the user to navigate back to the previous screen.
     *
     *  - Parameter controllerID: The ID of the controller to switch to.
     */
    func switchController(controllerID: String) {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: controllerID) as UIViewController
        self.present(vc, animated: true, completion: nil)
    }
}

extension LoginController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder() // Dismisses the keyboard.
        
        return true
    }
}
