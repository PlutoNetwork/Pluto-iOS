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
    
    // MARK - Outlets
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameField: TextField!
    @IBOutlet weak var emailField: TextField!
    
    // MARK - Variables
    
    var imagePicker: UIImagePickerController!
    var imageSelected = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setUserInfo()
        
        // Dismisses the keyboard if the user taps anywhere on the screen.
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SettingsVC.dismissKeyboard)))
        
        nameField.delegate = self
        emailField.delegate = self
        
        // Initializes the image picker.
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
    }
    
    // MARK - Button Actions
    
    @IBAction func saveButtonAction(_ sender: AnyObject) {
        
        if nameField.text != "" {
            
            DataService.ds.REF_CURRENT_USER.child("name").setValue(nameField.text!)
        }
        
        if imageSelected == true {
            
            uploadProfileImage()
        }
    }
    
    // MARK: - Firebase
    
    func setUserInfo() {
        
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            if value?["image"] != nil {
                
                self.downloadProfileImage(imageURL: (value?["image"] as? String)!)
            }
            
            if value?["name"] != nil {
                
                self.nameField.text = (value?["name"] as? String)
            }
            
            self.emailField.text = (value?["email"] as? String)
            
        }) { (error) in
            
            // Error!
            
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't set your information.")
        }
    }
    
    func downloadProfileImage(imageURL: String) {
        
        let ref = FIRStorage.storage().reference(forURL: imageURL)
        ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                // Error! Unable to download photo from Firebase storage.
                
            } else {
                
                // Image successfully downloaded from Firebase storage.
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        self.profileImageView.image = img
                        
                        // Save to image cache (globally declared in BoardVC)
                        BoardVC.imageCache.setObject(img, forKey: imageURL as NSString)
                    }
                }
            }
        })
    }

    func uploadProfileImage() {
        
        if let imageData = UIImageJPEGRepresentation(profileImageView.image!, 0.2) {
            
            let imageUID = NSUUID().uuidString
            
            // Tells Firebase storage what file type we're uploading.
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_PROFILE_PICS.child(imageUID).put(imageData, metadata: metadata) { (metadata, error) in
                
                if error != nil {
                    
                    // Error! The image could not be uploaded to Firebase storage.
                    
                } else {
                    
                    // Successfully uploaded image to Firebase storage.
                    
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    
                    self.updateUserPic(imageURL: downloadURL!)
                }
            }
        }
    }
    
    func updateUserPic(imageURL: String) {
        
        let userProfileRef = DataService.ds.REF_CURRENT_USER.child("image")
        userProfileRef.setValue(imageURL)
        
        imageSelected = false
    }
    
    // MARK - Gesture Actions
    
    @IBAction func chooseProfileImageAction(_ sender: AnyObject) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    func dismissKeyboard() {
        
        nameField.resignFirstResponder()
        emailField.resignFirstResponder()
    }
    
    // MARK: - Image Picker Functions
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // "Media" means it can be a video or an image.
        // We have to check to make sure it is an image the user picked.
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            profileImageView.image = image
            imageSelected = true
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Text Field Functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard.
        textField.resignFirstResponder()
        return true
    }
}
