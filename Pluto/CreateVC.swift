//
//  CreateVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/16/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class CreateVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate {

    // MARK: - Outlets
    
    @IBOutlet weak var createEventImageView: RoundImageView!
    @IBOutlet weak var createEventTitleField: UITextField!
    @IBOutlet weak var createEventLocationField: UITextField!
    @IBOutlet weak var createEventTimeField: UITextField!
    @IBOutlet weak var createEventDescriptionField: UITextView!
    
    // MARK: - Variables

    var imagePicker: UIImagePickerController!
    
    /// Tells when user has selected a picture for an event.
    var imageSelected = false
    
    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
        
        UIApplication.shared.isStatusBarHidden = true
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.title = "Create Event"
        self.navigationController?.navigationBar.backItem?.title = ""
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initializes the text fields.
        createEventTitleField.delegate = self
        createEventLocationField.delegate = self
        createEventTimeField.delegate = self
        createEventDescriptionField.delegate = self
        
        // Initializes the image picker.
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        // Adds a tap gesture to the createEventImageView to bring up the imagePicker.
        createEventImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CreateVC.addImageGesture)))
    }
    
    // MARK: - Button Actions
    
    @IBAction func backButtonAction(_ sender: AnyObject) {
        
        if createEventTitleField.text != "" || createEventLocationField.text != "" || createEventTimeField.text != "" {
            
            // Create an alert to ask the user if a new account should be created.
            let notice = SCLAlertView()
            
            notice.addButton("Yes!") {
                
                // The user has wants to leave the create screen.
                self.switchController(controllerID: "Main")
            }
            
            notice.showInfo("Hey!", subTitle: "You have unsaved changes here. Are you sure you want to head back to the main screen?", closeButtonTitle: "No, I made a mistake!")
        } else {
            
            switchController(controllerID: "Main")
        }
    }
    
    @IBAction func saveButtonAction(_ sender: AnyObject) {
        
        if createEventTitleField.text != "" && createEventLocationField.text != "" && createEventTimeField.text != "" {
            
            if imageSelected == true {
                                
                self.grabCurrentBoardID(uploadImage: true)
                
            } else {
                
                self.grabCurrentBoardID(uploadImage: false)
            }
        } else {
            
            SCLAlertView().showError("Oh no!", subTitle: "The event was not created because the required fields were left blank.")
        }
    }
    
    // MARK: - Datepicker Functions
    
    func datePickerChanged(sender: UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        
        let strDate = dateFormatter.string(from: sender.date)
        
        createEventTimeField.text = strDate
    }
    
    // MARK: - Firebase
    
    func createEvent(imageURL: String = "", boardKey: String, name: String) {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        // DO DATE FORMAT STUFF HERE
        // Make variable time that will hold the formatted date (2016-10-27 19:29:50 +0000)
        // Grab unformatted time from createEventTimeField.text!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        let event: Dictionary<String, Any> = [
            
            "title": createEventTitleField.text! as Any,
            "location": createEventLocationField.text! as Any,
            "time": createEventTimeField.text! as Any,
            "description": createEventDescriptionField.text! as Any,
            "creator": name as Any,
            "creatorID": userID! as Any,
            "count": 1 as Any,
            "imageURL": imageURL as Any
        ]
        
        let newEvent = DataService.ds.REF_BOARDS.child(boardKey).child("events").childByAutoId()
        newEvent.setValue(event)
        
        let userEventRef = DataService.ds.REF_CURRENT_USER.child("events").child(newEvent.key)
        userEventRef.setValue(true)
        
        createEventTitleField.text = ""
        createEventLocationField.text = ""
        createEventTimeField.text = ""
        createEventDescriptionField.text = ""
        imageSelected = false
        createEventImageView.image = UIImage(named: "camera_icon")
        
        switchController(controllerID: "Main")
    }
    
    func grabCurrentBoardID(uploadImage: Bool, imageURL: String = "") {
        
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            let currentBoardID = value?["board"] as? String
            self.grabUserName(uploadImage: uploadImage, imageURL: imageURL, boardKey: currentBoardID!)
        })
    }
    
    func grabUserName(uploadImage: Bool, imageURL: String = "", boardKey: String) {
        
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            var name = String()
            
            if value?["name"] as? String != nil {
            
                name = (value?["name"] as? String)!
                
            } else {
                
                name = (value?["email"] as? String)!
            }
            
            if uploadImage == true {
                
                self.uploadEventImage(boardKey: boardKey, name: name)
                
            } else {
                
                self.createEvent(imageURL: imageURL, boardKey: boardKey, name: name)
            }
        })
    }
    
    func uploadEventImage(boardKey: String, name: String) {
        
        if let imageData = UIImageJPEGRepresentation(createEventImageView.image!, 0.2) {
            
            let imageUID = NSUUID().uuidString
            
            // Tells Firebase storage what file type we're uploading.
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_EVENT_PICS.child(imageUID).put(imageData, metadata: metadata) { (metadata, error) in
                
                
                if error != nil {
                    
                    // Error! The image could not be uploaded to Firebase storage.
                    
                    print(error.debugDescription)
                    
                } else {
                    
                    // Successfully uploaded image to Firebase storage.
                    
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    self.createEvent(imageURL: downloadURL!, boardKey: boardKey, name: name)
                }
            }
        }
    }
    
    // MARK: - Gestures
    
    func addImageGesture() {
        
        present(imagePicker, animated: true, completion: nil)
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
    
    // MARK: - Image Picker Functions
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // "Media" means it can be a video or an image.
        // We have to check to make sure it is an image the user picked.
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            createEventImageView.image = image
            imageSelected = true
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Text Field Functions
    
    @IBAction func timeFieldEditingBegan(_ sender: TextField) {
        
        // First, we intialize a datePicker variable.
        let datePickerView: UIDatePicker = UIDatePicker()
        
        // This sets the format for the datepicker. In this case, it will show both date and time.
        datePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        
        // This changes the first responder of the text field from the keyboard to the datePicker initialized above.
        sender.inputView = datePickerView
        
        // This adds a target that updates the contents of the text field to match whatever the user is selecting in the datePicker.
        datePickerView.addTarget(self, action: #selector(CreateVC.datePickerChanged(sender:)), for: UIControlEvents.valueChanged)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Text View Functions
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clears "Description" text from textView window
        
        if createEventDescriptionField.text == "Description" {
            createEventDescriptionField.text = ""
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        createEventDescriptionField.resignFirstResponder()
    }
}
