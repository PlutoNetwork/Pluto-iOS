//
//  CreateVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/16/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit
import EventKit
import Firebase

class CreateController: UIViewController, UINavigationControllerDelegate {

    // MARK: - OUTLETS
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var imageInstructionLabel: UILabel!
    @IBOutlet weak var createEventImageView: UIImageView!
    @IBOutlet weak var createEventTitleField: UITextField!
    @IBOutlet weak var createEventLocationField: UITextField!
    @IBOutlet weak var createEventStartTimeField: TextField!
    @IBOutlet weak var createEventEndTimeField: TextField!
    @IBOutlet weak var createEventDescriptionField: TextView!
    
    @IBOutlet weak var deleteButton: Button!
    
    var calendar: EKCalendar!
    
    // MARK: - VARIABLES

    var navigationBarPostButton: UIBarButtonItem!
    var imagePicker: UIImagePickerController!
    var postButtonImage: UIImage!
    
    let startDatePickerView: UIDatePicker = UIDatePicker()
    let endDatePickerView: UIDatePicker = UIDatePicker()
    
    /// Holds the key of the event that may be passed from the detail screen.
    var event = Event(board: String(), count: Int(), creator: String(), description: String(), imageURL: String(), location: String(), timeStart: String(), timeEnd: String(), title: String())
    
    /// Tells when user enters screen from details page.
    var inEditingMode = false
    
    /// Tells when user has selected a picture for an event.
    var imageSelected = false
    
    // MARK: - VIEW
    
    override func viewWillAppear(_ animated: Bool) {
        
        /* Navigation bar customization */
        self.navigationController?.setNavigationBarHidden(false, animated: true) // Keeps the navigation bar unhidden.
        self.navigationItem.title = "Create Event" // Sets the title for the screen.
        self.navigationController?.navigationBar.backItem?.title = "" // Keeps the back button to a simple "<".
        self.navigationController?.navigationBar.tintColor = UIColor.white // Changes the content of the navigation bar to a white color.
        
        /* Checks the event for any data. If it contains data, it was passed from the details controller and means that the user has come to edit the event. */
        
        if event.title != "" {
            
            inEditingMode = true
            self.deleteButton.alpha = 1.0 // Unhide the delete button.
            setDetails()
        }
        
        /* Changes the post button to reflect editing or creating a new event. */
        
        if inEditingMode == true {
            
            postButtonImage = UIImage(named: "ic-check")
            
        } else {
            
            postButtonImage = UIImage(named: "ic-post-event")
        }
        
        /* Post button */
        navigationBarPostButton = UIBarButtonItem(image: postButtonImage, style: .plain, target: self, action: #selector(CreateController.saveAndPostEvent)) // Initializes a post button for the navigation bar.
        navigationBarPostButton.tintColor = UIColor.white // Changes the color of the post button to white.
        self.navigationItem.rightBarButtonItem  = navigationBarPostButton // Adds the post button to the navigation bar.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /* Initialization of the text fields. */
        createEventTitleField.delegate = self
        createEventLocationField.delegate = self
        createEventStartTimeField.delegate = self
        createEventEndTimeField.delegate = self
        createEventDescriptionField.delegate = self
        
        /* Initialization of the image picker. */
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        createEventImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CreateController.addImageGesture))) // Adds a tap gesture to the createEventImageView to bring up the imagePicker.
    }
    
    // MARK: - BUTTON
    
    @IBAction func deleteButtonAction(_ sender: Any) {
        
        /// Create an alert to show errors.
        let notice = SCLAlertView()
        
        notice.addButton("Yes!") {
            
            /* The user has given permission to delete the event. */
            DataService.ds.REF_EVENTS.child(self.event.eventKey).removeValue()
            DataService.ds.REF_CURRENT_USER_EVENTS.child(self.event.eventKey).removeValue()
            DataService.ds.REF_CURRENT_BOARD_EVENTS.child(self.event.eventKey).removeValue()
            
            self.switchController(controllerID: "Main")
        }
        
        notice.showInfo("Hey!", subTitle: "Are you sure you want to delete your event? Event-goers will be notified.", closeButtonTitle: "No, I made a mistake!")
    }
    
    /**
     *  #GATEWAY
     *
     *  Calls functions that upload the event image and save the new event to the database.
     */
    func saveAndPostEvent() {
        
        /* First we need to check to see if any of the fields were left blank. */
        
        if createEventTitleField.text != "" && createEventLocationField.text != "" && createEventStartTimeField.text != "" && createEventEndTimeField.text != "" && createEventImageView.image != nil {
            
            /* SUCCESS: The event will be created. */
        
            self.uploadEventImage()
            
        } else {
            
            /* ERROR: The event could not be created. */
            
            SCLAlertView().showError("Oh no!", subTitle: "The event was not created because the required fields were left blank.")
        }
    }
    
    func updateEvent(imageURL: String) {
        
        /// Holds the reference to the user's image key in the database.
        let eventRef = DataService.ds.REF_EVENTS.child(event.eventKey)
        
        // Sets the value for the updated fields.
        
        let updatedEvent = ["title": createEventTitleField.text! as Any,
                            "timeStart": createEventStartTimeField.text! as Any,
                            "timeEnd": createEventEndTimeField.text! as Any,
                            "location": createEventLocationField.text! as Any,
                            "description": createEventDescriptionField.text! as Any,
                            "imageURL": imageURL as Any]
        
        eventRef.updateChildValues(updatedEvent)
        
        switchController(controllerID: "Main")
    }
    
    // MARK: - HELPERS
    
    /**
     *  Changes the field contents to reflect the event data passed in.
     */
    func setDetails() {
        
        /* We can fill these in because this function can only be called if the event has data. */
        createEventTitleField.text = event.title
        createEventStartTimeField.text = event.timeStart
        createEventEndTimeField.text = event.timeEnd
        createEventLocationField.text = event.location
        createEventDescriptionField.text = event.description
        
        /// Holds the event image grabbed from the cache.
        if let img = BoardController.imageCache.object(forKey: event.imageURL as NSString) {
            
            /* SUCCESS: Loaded image from the cache. */
            
            if self.imageSelected == false {
                
                self.imageInstructionLabel.alpha = 0 // Hides the instruction label.
                self.createEventImageView.image = img // Sets the event image to the one grabbed from the cache.
            }
            
        } else {
            
            /* If it doesn't download from the cache for some reason, just download it from Firebase. */
            
            let ref = FIRStorage.storage().reference(forURL: event.imageURL)
            
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    /* ERROR: Unable to download photo from Firebase storage. */
                    
                } else {
                    
                    /* SUCCESS: Image downloaded from Firebase storage. */
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            self.createEventImageView.image = img
                        }
                    }
                }
            })
        }
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
            "timeStart": createEventStartTimeField.text! as Any,
            "timeEnd": createEventEndTimeField.text! as Any,
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
        
        let eventUserRef = DataService.ds.REF_EVENTS.child(newEventKey).child("users").child(userID!)
        eventUserRef.setValue(true)
        
        syncToCalendar(event: event)
        
        /* Clear the fields. */
        createEventTitleField.text = ""
        createEventLocationField.text = ""
        createEventStartTimeField.text = ""
        createEventEndTimeField.text = ""
        createEventDescriptionField.text = ""
        imageSelected = false
        createEventImageView.image = UIImage(named: "")
        imageInstructionLabel.alpha = 1.0
        
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
                    
                    if self.inEditingMode == true {
                        
                        self.updateEvent(imageURL: downloadURL!)
                        
                    } else {
                        
                        self.createEvent(imageURL: downloadURL!)
                    }                    
                }
            }
        }
    }
    
    
    // MARK: - CALENDAR
    
    func syncToCalendar(event: Dictionary<String, Any>) {
        
        let eventStore = EKEventStore()
        
        if EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized {
            
            eventStore.requestAccess(to: .event, completion: { (granted, error) in
                
                if error != nil {
                    
                    /* SUCCESS: We have access to modify the user's calendar. */
     
                    self.calendarCall(calEvent: eventStore, event: event)
                    
                } else {
                    
                    /* ERROR: Something went wrong and the user's calendar could not be accessed. */
                    
                    print(error.debugDescription)
                }
            })
            
        } else {
            
            // Code if we already have permission.
            
            calendarCall(calEvent: eventStore, event: event)
        }
    }
    
    func calendarCall(calEvent: EKEventStore, event: Dictionary<String, Any>){
        
        let newEvent = EKEvent(eventStore: calEvent)
        
        newEvent.title = event["title"] as! String //Sets event title
        
        //Formats the date and time to be useable by iOS calendar app
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.short
        let newEventStartTime = formatter.date(from: event["timeStart"] as! String)
        let newEventEndTime = formatter.date(from: event["timeEnd"] as! String)
        
        newEvent.startDate = newEventStartTime! // Sets start date and time for event
        newEvent.endDate = newEventEndTime! // Sets end date and time for event
        newEvent.location = event["location"] as! String? // Copies location into calendar
        newEvent.calendar = calEvent.defaultCalendarForNewEvents // Copies event into calendar
        newEvent.notes = event.description // Copies event description into calendar
        
        do {
            
            //Saves event to calendar
            try calEvent.save(newEvent, span: .thisEvent)
            
        } catch {
            
            print("OH NO")
        }
    }

}

extension CreateController: UIImagePickerControllerDelegate {
    
    /**
     *  Summons the image picker.
     */
    func addImageGesture() {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        /* "Media" means it can be a video or an image. */
        
        /* We have to check to make sure it is an image the user picked. */
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            self.imageInstructionLabel.alpha = 0
            self.createEventImageView.image = image
            imageSelected = true
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

extension CreateController: UITextFieldDelegate, UITextViewDelegate {
    
    func datePickerChanged(sender: UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        
        let strDate = dateFormatter.string(from: sender.date)
        
        if sender == startDatePickerView {
            
            createEventStartTimeField.text = strDate
            
        } else {
            
            createEventEndTimeField.text = strDate
        }
    }
    
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder() // Dismisses the keyboard.
        
        return true
    }
    
    @IBAction func timeFieldEditingBegan(_ sender: TextField) {
        
        /* This sets the format for the datepicker. In this case, it will show both date and time. */
        startDatePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        endDatePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        
        if sender == createEventStartTimeField {
            
            sender.inputView = startDatePickerView // Changes the first responder of the text field from the keyboard to the datePicker initialized above.
            
            /* We need to add a target that updates the contents of the text field to match whatever the user is selecting in the datePicker. */
            
            startDatePickerView.addTarget(self, action: #selector(CreateController.datePickerChanged(sender:)), for: UIControlEvents.valueChanged)
        
        } else {
            
            sender.inputView = endDatePickerView
            
            endDatePickerView.addTarget(self, action: #selector(CreateController.datePickerChanged(sender:)), for: UIControlEvents.valueChanged)
        }
        
        
    }
}
