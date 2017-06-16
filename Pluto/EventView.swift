//
//  EventDetailView.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/5/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

class EventView: UIView, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleField: TextField!
    @IBOutlet weak var timeStartField: TextField!
    @IBOutlet weak var timeEndField: TextField!
    
    @IBOutlet weak var saveButton: Button!
    @IBOutlet weak var deleteButton: Button!
    
    @IBOutlet weak var countLabel: UILabel!
    
    // MARK: - Variables
    
    var event: Event!
    var eventKey: String!
    var eventImageURL: String!
    var eventLocation: CLLocation! = CLLocation()
    var isNewEvent = false
    var isEventCreator = false
    
    var imagePicker: UIImagePickerController!
    
    var startDatePickerView: UIDatePicker = UIDatePicker()
    var endDatePickerView: UIDatePicker = UIDatePicker()
    
    /// Tells when user has selected a picture for an event.
    var imageSelected = false
    
    var notificationView: NotificationView!
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        setupView()
    }
    
    override func awakeFromNib() {
        
        titleField.delegate = self
        timeStartField.delegate = self
        timeEndField.delegate = self
            
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setupView()
    }
    
    func setupView() {
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 10.0
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.shadowColor = SHADOW_COLOR.cgColor
        self.setNeedsLayout()
        
        /* Initialization of the image picker. */
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(EventView.changeCount))
        doubleTap.delegate = self
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
        
        if isEventCreator || isNewEvent {
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(EventView.addImageGesture))
            tap.delegate = self
            tap.numberOfTapsRequired = 1
            imageView.addGestureRecognizer(tap)
            
            titleField.isUserInteractionEnabled = true
            timeStartField.isUserInteractionEnabled = true
            timeEndField.isUserInteractionEnabled = true
            timeStartField.addTarget(self, action: #selector(EventView.timeFieldEditingBegan(_:)), for: .editingDidBegin)
            timeEndField.addTarget(self, action: #selector(EventView.timeFieldEditingBegan(_:)), for: .editingDidBegin)
            
            saveButton.alpha = 1.0
            deleteButton.alpha = 1.0
        }
    }
    
    func setEventImage() {
        
        if let img = MainController.imageCache.object(forKey: eventImageURL as NSString) {
            
            self.imageView.image = img
            
        } else {
            
            let ref = Storage.storage().reference(forURL: eventImageURL)
            
            ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    /* ERROR: Unable to download photo from Firebase storage. */
                    
                } else {
                    
                    /* SUCCESS: Image downloaded from Firebase storage. */
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            MainController.imageCache.setObject(img, forKey: self.eventImageURL as NSString) // Save to image cache.
                            
                            self.imageView?.image = img
                        }
                    }
                }
            })
        }
    }
    
    func setEventLocation(coordinate: CLLocationCoordinate2D) {
        
        eventLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    func changeCount() {
        
        let userID = Auth.auth().currentUser?.uid
        
        let eventUserRef = DataService.ds.REF_EVENTS.child(event.eventKey).child("users").child(userID!)
        let userEventRef = DataService.ds.REF_CURRENT_USER.child("events").child(event.eventKey)
        
        userEventRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let _ = snapshot.value as? NSNull {
                
                //self.eventPlutoImageView.image = UIImage(named: "ship-yellow")
                self.event.adjustCount(addToCount: true)
                eventUserRef.setValue(true)
                userEventRef.setValue(true)
                //self.showNotificationView(title: "Successfully added event", subTitle: "Tap here to go to your calendar")
                //self.syncToCalendar(add: true)
                
            } else {
                
                //self.eventPlutoImageView.image = UIImage(named: "ship-faded")
                self.event.adjustCount(addToCount: false)
                eventUserRef.removeValue()
                userEventRef.removeValue()
                //self.showNotificationView(title: "Successfully removed event", subTitle: "")
                //self.syncToCalendar(add: false)
            }
        })
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
        
        titleField.resignFirstResponder()
        timeStartField.resignFirstResponder()
        timeEndField.resignFirstResponder()
        
        let updatedEvent = ["title": titleField.text! as Any,
                            "timeStart": timeStartField.text! as Any,
                            "timeEnd": timeEndField.text! as Any,
                            ]
        
        if imageSelected == true {
            
            if !isNewEvent {
                
                deleteEventImage()
            }
            
            uploadEventImage() // Adds the new event image.
        }
        
        if !isNewEvent {
            
            updateEvent(updatedEvent: updatedEvent)
        }
    }
    
    func createEvent(imageURL: String = "") {
        
        let userID = Auth.auth().currentUser?.uid
        
        /* Make variable time that will hold the formatted date (2016-10-27 19:29:50 +0000) */
        
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        /// An event created using data pulled from the form.
        let event: Dictionary<String, Any> = [
            
            "title": titleField.text! as Any,
            "timeStart": timeStartField.text! as Any,
            "timeEnd": timeEndField.text! as Any,
            "creator": userID! as Any,
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
        
        let eventUserRef = DataService.ds.REF_EVENTS.child(newEventKey).child("users").child(userID!)
        eventUserRef.setValue(true)
        
        //syncToCalendar(event: event)
        
        //let eventDict = event
        //let passEvent = Event(eventKey: newEvent.key, eventData: eventDict as Dictionary<String, AnyObject>)
        
        //self.event = passEvent
        
        //self.clearFields()
        
        let geoFire = GeoFire(firebaseRef: DataService.ds.REF_EVENT_LOCATIONS)
        geoFire?.setLocation(self.eventLocation, forKey: newEventKey)
        
        AnimationEngine.animateToPosition(view: self, position: AnimationEngine.offScreenLeftPosition)
        let superView = self.superview?.next as! MainController
        superView.blurView.alpha = 0
        superView.blurView = nil
        superView.vibrancyView = nil
        superView.eventDetailView = nil
    }
    
    func updateEvent(updatedEvent: [String : Any]) {
        
        DataService.ds.REF_EVENTS.child(self.eventKey).updateChildValues(updatedEvent)
        
        UIView.animate(withDuration: 0.5) {
            
            self.saveButton.alpha = 0
        }
    }
    
    @IBAction func deleteButtonAction(_ sender: Any) {
    
        DataService.ds.REF_EVENTS.child(self.eventKey).removeValue()
        DataService.ds.REF_EVENT_LOCATIONS.child(self.eventKey).removeValue()
        
        deleteEventImage()
        
        DataService.ds.REF_CURRENT_USER_EVENTS.child(self.eventKey).removeValue()
        
        AnimationEngine.animateToPosition(view: self, position: AnimationEngine.offScreenRightPosition)
        let superView = self.superview?.next as! MainController
        superView.blurView.alpha = 0
        superView.blurView = nil
        superView.vibrancyView = nil
        superView.eventDetailView = nil
    }
    
    func deleteEventImage() {
        
        let eventImageRef = Storage.storage().reference(forURL: self.eventImageURL)
        eventImageRef.delete { (error) in
            
            print(error.debugDescription)
        }
    }
    
    func uploadEventImage() {
        
        if let imageData = UIImageJPEGRepresentation(imageView.image!, 0.2) {
            
            let imageUID = NSUUID().uuidString
            
            /// Tells Firebase storage what file type we're uploading.
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_EVENT_PICS.child(imageUID).putData(imageData, metadata: metadata) { (metadata, error) in
                
                if error != nil {
                    
                    /* ERROR: The image could not be uploaded to Firebase storage. */
                    
                    SCLAlertView().showError("Oh no!", subTitle: "There was a problem uploading the image. Please try again later.")
                    
                } else {
                    
                    /* SUCCESS: Uploaded image to Firebase storage. */
                    
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    
                    if self.isNewEvent {
                        
                        self.createEvent(imageURL: downloadURL!)
                        
                    } else {
                        
                        let updatedEvent = ["imageURL": downloadURL as Any]
                        self.updateEvent(updatedEvent: updatedEvent)
                    }
                }
            }
        }
    }
    
    func showSaveButton() {
        
        UIView.animate(withDuration: 0.5) {
            
            self.saveButton.alpha = 1.0
        }
    }
    
    func showNotificationView(title: String, subTitle: String) {
        
        let superView = self.superview?.next as! MainController
        
        notificationView = Bundle.main.loadNibNamed("NotificationView", owner: self, options: nil)?[0] as? NotificationView
        notificationView.center = CGPoint(x: AnimationEngine.offScreenRightPosition.x, y: superView.userButton.center.y)
        notificationView.titleLabel.text = title
        notificationView.subtitleLabel.text = subTitle
        
        AnimationEngine.animateToPosition(view: notificationView, position: CGPoint(x: superView.view.center.x, y: superView.userButton.center.y))
        
        superView.view.addSubview(notificationView)
    }
}

extension EventView: UIImagePickerControllerDelegate {
    
    /**
     *  Summons the image picker.
     */
    func addImageGesture() {
        
        if saveButton.alpha != 1.0 {
            
            showSaveButton()
        }
        
        let superView = self.superview?.next as! MainController
        superView.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        /* "Media" means it can be a video or an image. */
        
        /* We have to check to make sure it is an image the user picked. */
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            self.imageView.image = image
            imageSelected = true
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

extension EventView: UITextFieldDelegate {
    
    func datePickerChanged(sender: UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        
        let strDate = dateFormatter.string(from: sender.date)
        
        if sender == startDatePickerView {
            
            timeStartField.text = strDate
            
        } else {
            
            timeEndField.text = strDate
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder() // Dismisses the keyboard.
        
        return true
    }
    
    func timeFieldEditingBegan(_ sender: TextField) {
                
        /* This sets the format for the datepicker. In this case, it will show both date and time. */
        startDatePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        endDatePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        
        if sender == timeStartField {
            
            sender.inputView = startDatePickerView // Changes the first responder of the text field from the keyboard to the datePicker initialized above.
            
            /* We need to add a target that updates the contents of the text field to match whatever the user is selecting in the datePicker. */
            
            startDatePickerView.addTarget(self, action: #selector(EventView.datePickerChanged(sender:)), for: UIControlEvents.valueChanged)
            
        } else {
            
            endDatePickerView.date = startDatePickerView.date
            
            sender.inputView = endDatePickerView
            
            endDatePickerView.addTarget(self, action: #selector(EventView.datePickerChanged(sender:)), for: UIControlEvents.valueChanged)
        }
    }
}

extension EventView: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        textView.resignFirstResponder()
    }
}

