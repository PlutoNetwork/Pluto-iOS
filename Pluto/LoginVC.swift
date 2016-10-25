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
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var goButton: Button!
            
    // MARK: - View Functions
    
    override func viewDidAppear(_ animated: Bool) {
        
        /// Grabs the email and password saved in a previous instance if the user already exists.
        let userDefaults = UserDefaults.standard
        
        // Checks to see if there is an email saved in the userDefaults.
        if (userDefaults.string(forKey: "email") != nil) {
            
            // Switches to the main board screen.
            self.switchController(controllerID: "Main")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initializes the text fields.
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    // MARK: - Button Actions
    
    @IBAction func goButtonAction(_ sender: AnyObject) {
        
        dismissKeyboard()
        firebaseLoginSignupVoodoo(email: emailField.text!, password: passwordField.text!)
    }
    
    // MARK: - Firebase
    
    /**
     Firebase authorization checks to see if the user has an account by trying to recognize the email and password. If it isn't found, an error will tell us that there is no account with those credentials. An account will then be created.
     
     - Parameter email: The email from the emailField.text (provided by the user).
     - Parameter password: The password from the passwordField.text (provided by the user).
     
     - Todo: Create alerts to notify the user what *specific* error occurs.
     */
    func firebaseLoginSignupVoodoo(email: String, password: String) {
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            
            if error == nil {
                
                // Success! The user has logged in!
                
                self.saveDefault(email: email, password: password)
                
                self.clearFields()
                
                // Transitions to the main board screen.
                self.switchController(controllerID: "Main")
                
            } else {
                
                // Error!
                
                // Firebase couldn't match the credentials of the account to an existing one, so a new account is created *after* the user is asked if an account should be created.
                if error?._code == STATUS_ACCOUNT_NONEXIST {
                    
                    // Create an alert to ask the user if a new account should be created.
                    let notice = SCLAlertView()
                    
                    notice.addButton("Yes!") {
                        
                        // The user has given permission to create him/her an account.
                        
                        // Firebase does some voodoo to create the user an account with the provided information.
                        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                            
                            if error != nil {
                                
                                // Error! Something went wrong creating an account.
                                SCLAlertView().showError("Oh no!", subTitle: "Pluto could not create an account for you at this time.")
                                
                            } else {
                                
                                // Success! The user has been created!
                                
                                self.saveUser(user: user!, userID: (user?.uid)!, email: email, password: password, providerID: (user?.providerID)!)
                                self.performSegue(withIdentifier: "showSearch", sender: self)
                            }
                        })
                    }
                    
                    notice.showInfo("Hey!", subTitle: "Pluto couldn't find an account with these credentials. Should we create you a new account?", closeButtonTitle: "No, I made a mistake!")
                    
                } else {
                    
                    // Error! This means something went wrong that wasn't caught above.
                    SCLAlertView().showError("Oh no!", subTitle: "Pluto could not log you in at this time because of an unknown error.")
                }
            }
        })
    }
        
    /**
     Saves the user to the Firebase database.
     
     - Parameter user: The user that was created by Firebase and successfully authorized.
     - Parameter userID: The user's unique ID.
     - Parameter email: The user's email inputted in the emailField.text.
     - Parameter providerID: How the user signed up (Firebase, Facebook, Google, etc.).
     */
    func saveToDatabaseVoodoo(user: FIRUser?, userID: String, email: String, providerID: String) {
        
        if let user = user {
            
            // Creates a dictionary for the user information that will be saved to the database.
            let userData = ["provider": providerID,
                            "email": email]
            
            DataService.ds.createFirebaseDBUser(uid: user.uid, userData: userData)
        }
    }
    
    // MARK: - Helpers
    
    /**
     Simple animation that fades the view given in or out.
     
     - Parameter view: The element that the animation will be done on.
     - Parameter alpha: How transparent the view should be after the animation plays out.
     */
    func animateFade(view: UIView, alpha: CGFloat) {
        
        UIView.animate(withDuration: 0.3) {
            
            view.alpha = alpha
        }
    }
    
    func clearFields() {
        
        emailField.text = ""
        passwordField.text = ""
    }
    
    /**
     Dismisses the keyboard!
     
     Just put whatever textfields you want included here in the function.
     */
    func dismissKeyboard() {
        
        // Dismisses the keyboard for these text fields.
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    /**
     Saves the user's email and password to NSUserDefaults to bypass login for future use.
     
     - Parameter email: The email from the emailField.text (provided by the user).
     - Parameter password: The password from the passwordField.text (provided by the user).
     */
    func saveDefault(email: String, password: String) {
        
        let userDefaults = UserDefaults.standard
        
        // Save the email and password into userDefaults.
        userDefaults.set(email, forKey: "email")
        userDefaults.set(password, forKey: "password")
    }
    
    /**
     This is a gateway function; it's only purpose is to avoid repetitive function calling when saving the user.
     
     - Parameter user: The user that was created by Firebase and successfully authorized.
     - Parameter userID: The user's unique ID.
     - Parameter email: The user's email inputted in the emailField.text.
     - Parameter password: The user's password inputted in the passwordField.text.
     - Parameter providerID: How the user signed up (Firebase, Facebook, Google, etc.).
     */
    func saveUser(user: FIRUser?, userID: String?, email: String, password: String, providerID: String) {
        
        saveToDatabaseVoodoo(user: user, userID: userID!, email: email, providerID: providerID)
        saveDefault(email: email, password: password)
    }
    
    /**
     Switches to the view controller specified by the parameter.
     
     - Parameter controllerID: The ID of the controller to switch to.
     */
    func switchController(controllerID: String) {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: controllerID) as UIViewController
        self.present(vc, animated: true, completion: nil)
    }
        
    
    // MARK: - Text Field Functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard.
        textField.resignFirstResponder()
        
        return true
    }
}
