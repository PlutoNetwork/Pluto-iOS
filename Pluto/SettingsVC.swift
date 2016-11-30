//
//  SettingsVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/13/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Eureka
import Firebase
import UIKit

class SettingsVC: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.isStatusBarHidden = true
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ImageRow.defaultCellUpdate = { cell, row in
            cell.accessoryView?.layer.cornerRadius = 17
            cell.accessoryView?.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        }
        
        
        setUserInfo()
    }
    

    func logOut() {
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(nil, forKey: "email")
        
        try! FIRAuth.auth()?.signOut()
        
        switchController(controllerID: "Login")
    }
    
    // MARK: - Firebase
    
    /**
     Goes into Firebase storage to download the user's set profile image.
     
     - Parameter imageURL: A string that holds a reference to where the image is stored in the Firebase storage.
     */
    func downloadProfileImage(imageURL: String) {
        
        /// Uses the parameter (imageURL) to make a complete link to where the image is stored in the Firebase storage.
        let ref = FIRStorage.storage().reference(forURL: imageURL)
        
        // withMaxSize was computed in a tutorial online that found it to be ideal for the limit.
        ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                // Error! Unable to download photo from Firebase storage.
                SCLAlertView().showError("Oh no!", subTitle: "Pluto was unable to find your profile photo.")
                
            } else {
                
                // Success! Image successfully downloaded from Firebase storage.
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        // Save to image cache (globally declared in BoardVC).
                        BoardVC.imageCache.setObject(img, forKey: imageURL as NSString)
                    }
                }
            }
        })
    }
    
    /**
     Called when the user first opens up the settings view.
     
     Sets the name, email, and profile picture of the user. If any of these had not been set beforehand, placeholder text and a placeholder image is set instead.
    */
    func setUserInfo() {
        
        // Opens up the information under the current user in Firebase.
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            
            /// Holds each dictionary under the current user in Firebase.
            let value = snapshot.value as? NSDictionary
            
            if value?["image"] != nil {
                
                // Downloads the set profile image.
                self.downloadProfileImage(imageURL: (value?["image"] as? String)!)
            }
            
            self.form +++ Section("Basic Info")
                <<< ImageRow() { row in
                    
                    row.title = "Update profile picture"
                    
                }.onChange({ (row) in
                    
                    self.uploadProfileImage(row: row)
                })
                <<< TextRow() { row in
                        
                    row.title = "Name"
                    
                    if value?["name"] != nil {
                        
                        row.placeholder = value?["name"] as? String
                        
                    } else {
                        
                        row.placeholder = "What's your name?"
                    }
                }.onChange({ (row) in
                    
                    DataService.ds.REF_CURRENT_USER.child("name").setValue(row.value)
                })
                <<< EmailRow() { row in
                    
                    row.title = "Email"
                    
                    row.placeholder = value?["email"] as? String
                }.onChange({ (row) in
                    
                    DataService.ds.REF_CURRENT_USER.child("email").setValue(row.value)
                })
            
            
            self.form +++ Section("App Settings")
                <<< ButtonRow() { row in
                    row.title = "Log out"
                }.onCellSelection({ (cell, row) in
                    self.logOut()
                })
            
            self.form +++ ButtonRow() { row in
                row.title = "Save and return"
                }.onCellSelection({ (cell, row) in
                    self.switchController(controllerID: "Main")
                })
            
        }) { (error) in
            
            // Error! The information could not be received from Firebase.
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't set your information.")
        }
    }
    
    /**
     Called when the picture the user selected successfully uploads to the Firebase storage.
     
     Here the imageURL is saved under the current user's data in the Firebase database.
     
     - Parameter imageURL: A string that holds a reference to where the image is stored in the Firebase storage.
     */
    func updateUserData(imageURL: String) {
        
        /// Holds the reference to the user's image key in the database.
        let userProfileRef = DataService.ds.REF_CURRENT_USER.child("image")
        // Sets the value for the image key to the parameter (imageURL).
        userProfileRef.setValue(imageURL)
    }
    
    /**
     Called when the user selects an image and attempts to save.
     
     The image is saved as data and an ID is generated that allows it to be saved in the Firebase storage.
     */
    func uploadProfileImage(row: ImageRow) {
        
        // Grabs the image from the profileImageView and compresses it by the scale given.
        if let imageData = UIImageJPEGRepresentation(row.value!, 0.2) {
            
            /// Holds a unique id for the image being uploaded.
            let imageUID = NSUUID().uuidString
            
            // Tells Firebase storage what file type is being uploaded.
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            // Opens up the profile pics folder in the Firebase storage so the image can be uploaded.
            DataService.ds.REF_PROFILE_PICS.child(imageUID).put(imageData, metadata: metadata) { (metadata, error) in
                
                if error != nil {
                    
                    // Error! The image could not be uploaded to Firebase storage.
                    
                } else {
                    
                    // Success! Uploaded image to Firebase storage.
                    
                    /// Holds the imageURL that can be used as a reference in the database.
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    
                    self.updateUserData(imageURL: downloadURL!)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
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
        
        // Dismisses the keyboard when the return button is pressed on the keyboard.
        textField.resignFirstResponder()
        
        return true
    }
}
