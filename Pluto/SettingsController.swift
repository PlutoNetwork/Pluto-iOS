//
//  SettingsVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/13/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class SettingsController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    // MARK: - VARIABLES
    
    var navigationBarSaveButton: UIBarButtonItem!
    
    /// This is the gallery that opens up to let the user select an image from their photo library.
    var imagePicker: UIImagePickerController!
    
    /// Tells if the user has updated their profile image. Turns true if an image is selected in the imagePicker.
    var imageSelected = false
    
    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.title = "Settings"
        self.navigationController?.navigationBar.backItem?.title = ""
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        /* Save button */
        navigationBarSaveButton = UIBarButtonItem(image: UIImage(named: "ic-check"), style: .plain, target: self, action: #selector(SettingsController.save))
        navigationBarSaveButton.tintColor = UIColor.white
        self.navigationItem.rightBarButtonItem  = navigationBarSaveButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dismisses the keyboard if the user taps anywhere on the screen.
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SettingsController.dismissKeyboard)))
        
        // Initializes the text fields.
        nameField.delegate = self
        emailField.delegate = self
        
        // Initializes the image picker.
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        // Allows the user to select which portion of their selected image is to be used.
        imagePicker.allowsEditing = true
        
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SettingsController.addImageGesture))) // Adds a tap gesture to the profileImageView to bring up the imagePicker.
        
        setUserInfo()
    }
    
    @IBAction func logoutButtonAction(_ sender: Any) {
        
        logOut()
    }
    
    
    func logOut() {
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(nil, forKey: "email")
        
        try! FIRAuth.auth()?.signOut()
        
        switchController(controllerID: "Login")
    }
    
    func save() {
        
        // Checks to see if the user updated the name field.
        if nameField.text != "" {
            
            // Goes into Firebase to set the user's name to what they typed into the name field.
            DataService.ds.REF_CURRENT_USER.child("name").setValue(nameField.text!)
        }
        
        switchController(controllerID: "Main")
    }
    
    // MARK: - FIREBASE
    
    /**
     Goes into Firebase storage to download the user's set profile image.
     
     - Parameter imageURL: A string that holds a reference to where the image is stored in the Firebase storage.
     */
    func downloadProfileImage(image: String) {
        
        /// Holds the event image grabbed from the cache.
        if let img = BoardController.imageCache.object(forKey: image as NSString) {
            
            /* SUCCESS: Loaded image from the cache. */
            
            self.profileImageView.image = img
            
        } else {
            
            /* ERROR: Could not load the event image. */
            
            /* If it doesn't download from the cache for some reason, just download it from Firebase. */
            
            let ref = FIRStorage.storage().reference(forURL: image)
            
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    /* ERROR: Unable to download photo from Firebase storage. */
                    
                } else {
                    
                    /* SUCCESS: Image downloaded from Firebase storage. */
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            self.profileImageView.image = img
                        }
                    }
                }
            })
        }
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
            
            let name = value?["name"] as? String
            let email = value?["email"] as? String
            let image = value?["image"] as? String
            
            self.downloadProfileImage(image: image!)
            
            if name != email {
                
                self.nameField.text = name
                
            }
            
            self.emailField.text = email
            
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
                    
                    // ERROR: The image could not be uploaded to Firebase storage.
                    
                } else {
                    
                    // SUCCESS: Uploaded image to Firebase storage.
                    
                    /// Holds the imageURL that can be used as a reference in the database.
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    
                    self.updateUserData(imageURL: downloadURL!)
                }
            }
        }
    }
    
    // MARK: - HELPERS
    
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
}

extension SettingsController: UIImagePickerControllerDelegate {
    
    /**
     *  Summons the image picker.
     */
    func addImageGesture() {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // This function is called when something in the imagePicker is selected.
        
        // "Media" means it can be a video or an image.
        // Checks to make sure it is an image the user picked.
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            // Sets the profileImageView to the selected image.
            self.profileImageView.image = image
            
            // Sets the imageSelected to true because the user is now updating his profile picture and Pluto needs to save it.
            imageSelected = true
            self.uploadProfileImage()
        }
        
        // Hides the imagePicker.
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

extension SettingsController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard when the return button is pressed on the keyboard.
        textField.resignFirstResponder()
        
        return true
    }
}
