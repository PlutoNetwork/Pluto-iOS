//
//  CreateVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/16/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class CreateController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate {

    // MARK: - OUTLETS
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var createEventImageView: RoundImageView!
    @IBOutlet weak var createEventTitleField: UITextField!
    @IBOutlet weak var createEventLocationField: UITextField!
    @IBOutlet weak var createEventTimeField: UITextField!
    @IBOutlet weak var createEventDescriptionField: TextView!
    
    // MARK: - VARIABLES

    /* Elements */
    var navigationBarPostButton: UIBarButtonItem!
    var imagePicker: UIImagePickerController!
    
    /// Tells when user has selected a picture for an event.
    var imageSelected = false
    
    // MARK: - VIEW
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(false, animated: true) // Keeps the navigation bar unhidden.
        
        self.navigationItem.title = "Create Event" // Sets the title for the screen.
        
        self.navigationController?.navigationBar.backItem?.title = "" // Keeps the back button to a simple "<".
        
        self.navigationController?.navigationBar.tintColor = UIColor.white // Changes the content of the navigation bar to a white color.
        
        navigationBarPostButton = UIBarButtonItem(image: UIImage(named: "ic-post-event"), style: .plain, target: self, action: #selector(CreateController.saveAndPostEvent)) // Initializes a post button for the navigation bar.
        
        navigationBarPostButton.tintColor = UIColor.white // Changes the color of the post button to white.
        
        self.navigationItem.rightBarButtonItem  = navigationBarPostButton // Adds the post button to the navigation bar.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /* Initialization of the text fields. */
        createEventTitleField.delegate = self
        createEventLocationField.delegate = self
        createEventTimeField.delegate = self
        createEventDescriptionField.delegate = self
        
        /* Initialization of the image picker. */
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        createEventImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CreateController.addImageGesture))) // Adds a tap gesture to the createEventImageView to bring up the imagePicker.
    }
    
    // MARK: - BUTTON
    
    /**
     *  #GATEWAY
     *
     *  Calls functions that upload the event image and save the new event to the database.
     */
    func saveAndPostEvent() {
        
        /* First we need to check to see if any of the fields were left blank. */
        
        if createEventTitleField.text != "" && createEventLocationField.text != "" && createEventTimeField.text != "" && imageSelected == true {
            
            /* SUCCESS: The event will be created. */
            
            self.uploadEventImage()
            
        } else {
            
            /* ERROR: The event could not be created. */
            
            SCLAlertView().showError("Oh no!", subTitle: "The event was not created because the required fields were left blank.")
        }
    }
    
    // MARK: - DATEPICKER
    
    func datePickerChanged(sender: UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        
        let strDate = dateFormatter.string(from: sender.date)
        
        createEventTimeField.text = strDate
    }
    
    // MARK: - HELPERS
    
    /**
     Switches to the view controller specified by the parameter.
     
     - Parameter controllerID: The ID of the controller to switch to.
     */
    func switchController(controllerID: String) {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: controllerID) as UIViewController
        self.present(vc, animated: true, completion: nil)
    }
    
    // MARK: - FIREBASE
    
    /**
     *  #DATABASE
     *
     *  Creates an event using data from the form that will be added to the Firebase database.
     */
    func createEvent(imageURL: String = "") {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        let userDefaults = UserDefaults.standard
        
        let boardKey = userDefaults.string(forKey: "boardKey")
        
        /* Make variable time that will hold the formatted date (2016-10-27 19:29:50 +0000) */

        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        /// An event created using data pulled from the form.
        let event: Dictionary<String, Any> = [
            
            "title": createEventTitleField.text! as Any,
            "location": createEventLocationField.text! as Any,
            "time": createEventTimeField.text! as Any,
            "description": createEventDescriptionField.text! as Any,
            "creator": userID! as Any,
            "board": boardKey! as Any,
            "count": 1 as Any,
            "imageURL": imageURL as Any
        ]
        
        /// An event created on Firebase with a random key.
        let newEvent = DataService.ds.REF_EVENTS.childByAutoId()
        
        /// Uses the event model to add data to the event created on Firebase.
        newEvent.setValue(event)
        
        /// The key for the event created on Firebase.
        let newEventKey = newEvent.key
        
        /// A reference to the new event under the current user.
        let userEventRef = DataService.ds.REF_CURRENT_USER.child("events").child(newEventKey)
        
        userEventRef.setValue(true) // Sets the value to true indicating the event is under the user.
        
        /// A reference to the new event under the current board.
        let boardEventRef = DataService.ds.REF_CURRENT_BOARD.child("events").child(newEventKey)
        
        boardEventRef.setValue(true) // Sets the value to true indicating the event is under the board.
        
        /* Clear the fields. */
        createEventTitleField.text = ""
        createEventLocationField.text = ""
        createEventTimeField.text = ""
        createEventDescriptionField.text = ""
        imageSelected = false
        createEventImageView.image = UIImage(named: "")
        
        self.switchController(controllerID: "Main") // Switch back to the board.
    }
    
    /**
     *  #STORAGE
     *
     *  Uploads the image the user selected for the event to Firebase storage.
     */
    func uploadEventImage() {
        
        if let imageData = UIImageJPEGRepresentation(createEventImageView.image!, 0.2) {
            
            let imageUID = NSUUID().uuidString
            
            /// Tells Firebase storage what file type we're uploading.
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_EVENT_PICS.child(imageUID).put(imageData, metadata: metadata) { (metadata, error) in
                
                if error != nil {
                    
                    /* ERROR: The image could not be uploaded to Firebase storage. */
                    
                    SCLAlertView().showError("Oh no!", subTitle: "There was a problem uploading the image. Please try again later.")
                    
                } else {
                    
                    /* SUCCESS: Uploaded image to Firebase storage. */
                    
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    
                    self.createEvent(imageURL: downloadURL!)
                }
            }
        }
    }
    
    // MARK: - GESTURES
    
    /**
     *  Summons the image picker.
     */
    func addImageGesture() {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - IMAGE PICKER
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        /* "Media" means it can be a video or an image. */
        
        /* We have to check to make sure it is an image the user picked. */
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            createEventImageView.image = image
            imageSelected = true
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - TEXT FIELD
    
    @IBAction func timeFieldEditingBegan(_ sender: TextField) {
        
        let datePickerView: UIDatePicker = UIDatePicker() // First, we intialize a datePicker variable.
    
        datePickerView.datePickerMode = UIDatePickerMode.dateAndTime // This sets the format for the datepicker. In this case, it will show both date and time.
        
        sender.inputView = datePickerView // Changes the first responder of the text field from the keyboard to the datePicker initialized above.
        
        /* We need to add a target that updates the contents of the text field to match whatever the user is selecting in the datePicker. */
        
        datePickerView.addTarget(self, action: #selector(CreateController.datePickerChanged(sender:)), for: UIControlEvents.valueChanged)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder() // Dismisses the keyboard.

        return true
    }
    
    // MARK: - Text View Functions
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        /* Clears "Description" text from textView window. */
        if createEventDescriptionField.text == "Description" {
            
            createEventDescriptionField.text = ""
        }
        
        scrollView.setContentOffset(CGPoint(x: 0, y: 250), animated: true) // Shoots the description field up so the user can see what he/she is typing.
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        /* Check to see if the user presses the return key. */
        if text == "\n" {
            
            createEventDescriptionField.resignFirstResponder() // Dismisses the keyboard.
            
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true) // Brings the description field back down.
            return false
        }
            
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
    }
}
