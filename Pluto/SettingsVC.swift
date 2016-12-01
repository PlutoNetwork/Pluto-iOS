//
//  SettingsVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/13/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class SettingsVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var profileImageView: RoundImageView!
    @IBOutlet weak var nameField: HoshiTextField!
    @IBOutlet weak var emailField: HoshiTextField!
    
    // MARK: - Variables
    
    /// This is the gallery that opens up to let the user select an image from their photo library.
    var imagePicker: UIImagePickerController!
    
    /// Tells if the user has updated their profile image. Turns true if an image is selected in the imagePicker.
    var imageSelected = false
    
    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.isStatusBarHidden = true
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.title = "Profile Settings"
        self.navigationController?.navigationBar.backItem?.title = ""
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUserInfo()
        
        // Dismisses the keyboard if the user taps anywhere on the screen.
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SettingsVC.dismissKeyboard)))
        
        // Initializes the text fields.
        nameField.delegate = self
        emailField.delegate = self
        
        // Initializes the image picker.
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        // Allows the user to select which portion of their selected image is to be used.
        imagePicker.allowsEditing = true
    }
    
    func logOut() {
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(nil, forKey: "email")
        
        try! FIRAuth.auth()?.signOut()
        
        switchController(controllerID: "Login")
    }
    
    // MARK: - Button Actions
    
    @IBAction func saveButtonAction(_ sender: AnyObject) {
        
        // Checks to see if the user updated the name field.
        if nameField.text != "" {
            
            // Goes into Firebase to set the user's name to what they typed into the name field.
            DataService.ds.REF_CURRENT_USER.child("name").setValue(nameField.text!)
        }
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
                
                // Instead, set the profile image view to the profile placeholder image.
                self.profileImageView.image = UIImage(named: "profile_img_placeholder")
                
            } else {
                
                // Success! Image successfully downloaded from Firebase storage.
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        // Set the profile image view to the downloaded image.
                        self.profileImageView.image = img
                        
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
            
            if value?["name"] != nil {
                
                self.nameField.text = value?["name"] as? String
                
            } else {
                
                self.nameField.text = "What's your name?"
            }
            
            self.emailField.text = value?["email"] as! String
            
        }) { (error) in
            
            // Error! The information could not be received from Firebase.
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't find your information.")
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
        
        // Sets the imageSelected false to indicate the image is done uploading and can be updated again.
        imageSelected = false
    }
    
    /**
     Called when the user selects an image and attempts to save.
     
     The image is saved as data and an ID is generated that allows it to be saved in the Firebase storage.
     */
    func uploadProfileImage() {
        
        // Grabs the image from the profileImageView and compresses it by the scale given.
        if let imageData = UIImageJPEGRepresentation(profileImageView.image!, 0.2) {
            
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
     Dismisses the keyboard!
     
     Just put whatever textfields you want included here in the function.
     */
    func dismissKeyboard() {
        
        nameField.resignFirstResponder()
        emailField.resignFirstResponder()
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
    
    // MARK: - Image Picker Functions
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // This function is called when something in the imagePicker is selected.
        
        // "Media" means it can be a video or an image.
        // Checks to make sure it is an image the user picked.
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            // Sets the profileImageView to the selected image.
            profileImageView.image = image
            
            // Sets the imageSelected to true because the user is now updating his profile picture and Pluto needs to save it.
            imageSelected = true
            self.uploadProfileImage()
        }
        
        // Hides the imagePicker.
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Text Field Functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard when the return button is pressed on the keyboard.
        textField.resignFirstResponder()
        
        return true
    }
}
