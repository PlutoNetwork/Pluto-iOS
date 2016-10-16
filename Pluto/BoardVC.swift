//
//  BoardVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import FoldingTabBar
import UIKit

class BoardVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, YALTabBarDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var schoolNameLabel: UILabel!
    @IBOutlet weak var eventView: UITableView!
    @IBOutlet weak var shadeView: UIView!
    
    @IBOutlet weak var createEventAlert: UIView!
    @IBOutlet weak var createEventImageView: UIImageView!
    @IBOutlet weak var createEventTitleField: TextField!
    @IBOutlet weak var createEventLocationField: UITextField!
    @IBOutlet weak var createEventTimeField: TextField!
    @IBOutlet weak var createEventDescriptionField: UITextView!
    
    // MARK: - Variables
    
    /// Global image cache that holds all event and profile pictures.
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    /// Holds all the event data received from Firebase.
    var events = [Event]()
    
    /// Tells when user has tapped on an event for more details.
    var eventSelected = false
    /// Holds the index of the event the user taps on.
    var indexOfEventSelected = -1
    
    /// Tells when user has called the create event alert.
    var inCreatePostMode = false
    
    var imagePicker: UIImagePickerController!
    
    /// Tells when user has selected a picture for an event.
    var imageSelected = false
    
    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
        
        // This function is called BEFORE the view loads.
        
        /// Grabs the email and password saved in a previous instance if the user already exists.
        let userDefaults = UserDefaults.standard
        
        // Checks to see if there is an email saved in the userdefaults.
        if (userDefaults.string(forKey: "email") == nil) {
            
            // Switches to the login screen.
            self.tabBarController?.selectedIndex = 2
            
        } else {
            
            // There is a user logged in, set data.
            
            setBoardTitle()
            setEvents()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initializes the table view that holds all the events.
        eventView.delegate = self
        eventView.dataSource = self
        
        // Initializes the text fields.
        createEventTitleField.delegate = self
        createEventLocationField.delegate = self
        createEventTimeField.delegate = self
        
        // Initializes the image picker.
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        // Adds a tap gesture to the createEventImageView to bring up the imagePicker.
        createEventImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BoardVC.addImageGesture(_:))))
    }
    
    // MARK: Datepicker Functions
    
    func datePickerChanged(sender: UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        
        let strDate = dateFormatter.string(from: sender.date)
        
        createEventTimeField.text = strDate
        
    }
    
    // MARK: - Firebase
    
    func createEvent(imageURL: String = "") {
        
        let userDefaults = UserDefaults.standard
        
        let event: Dictionary<String, AnyObject> = [
            
            "title": createEventTitleField.text! as AnyObject,
            "location": createEventLocationField.text! as AnyObject,
            "time": createEventTimeField.text! as AnyObject,
            "description": createEventDescriptionField.text! as AnyObject,
            "creator": "" as AnyObject,
            "count": 1 as AnyObject,
            "imageURL": imageURL as AnyObject
        ]
        
        let newEvent = DataService.ds.REF_BOARDS.child(userDefaults.string(forKey: "board")!).child("events").childByAutoId()
        newEvent.setValue(event)
        
        let userEventRef = DataService.ds.REF_CURRENT_USER.child("events").child(newEvent.key)
        userEventRef.setValue(true)
        
        createEventTitleField.text = ""
        createEventTimeField.text = ""
        imageSelected = false
        createEventImageView.image = UIImage(named: "camera_icon")
    }
    
    func setBoardTitle() {
        
        let userDefaults = UserDefaults.standard
        
        DataService.ds.REF_BOARDS.child(userDefaults.string(forKey: "board")!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            
            let value = snapshot.value as? NSDictionary
            
            if value?["title"] != nil {
                self.schoolNameLabel.text = (value?["title"] as? String)?.uppercased()
            }
            
        }) { (error) in
            
            // Error!
            
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't find your school.")
        }
    }
    
    func setEvents() {
        
        let userDefaults = UserDefaults.standard
        
        DataService.ds.REF_BOARDS.child(userDefaults.string(forKey: "board")!).child("events").observe(.value, with: { (snapshot) in
            
            self.events = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        let event = Event(eventKey: key, eventData: eventDict)
                        self.events.append(event)
                    }
                }
            }
            
            self.eventView.reloadData()
        })
    }
    
    func uploadEventImage() {
        
        if let imageData = UIImageJPEGRepresentation(createEventImageView.image!, 0.2) {
            
            let imageUID = NSUUID().uuidString
            
            // Tells Firebase storage what file type we're uploading.
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_EVENT_PICS.child(imageUID).put(imageData, metadata: metadata) { (metadata, error) in
                
                if error != nil {
                    
                    // Error! The image could not be uploaded to Firebase storage.
                    
                } else {
                    
                    // Successfully uploaded image to Firebase storage.
                    
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    self.createEvent(imageURL: downloadURL!)
                }
            }
        }
    }
    
    // MARK: - Gestures
    
    @IBAction func addImageGesture(_ sender: AnyObject) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    func animateFade(view: UIView, alpha: CGFloat) {
        
        UIView.animate(withDuration: 0.3) {
            
            view.alpha = alpha
        }
    }
    
    func dismissKeyboard() {
        
        createEventTitleField.resignFirstResponder()
        createEventLocationField.resignFirstResponder()
        createEventTimeField.resignFirstResponder()
        createEventDescriptionField.resignFirstResponder()
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
    
    // MARK: - Tab Bar Functions
    
    func tabBarDidSelectExtraRightItem(_ tabBar: YALFoldingTabBar) {
        
        if inCreatePostMode == false {
            
            animateFade(view: shadeView, alpha: 0.6)
            animateFade(view: createEventAlert, alpha: 1.0)
            
            createEventAlert.clipsToBounds = true
            
            inCreatePostMode = true
            
        } else {
            
            if createEventTitleField.text != "" && createEventLocationField.text != "" && createEventTimeField.text != "" {
                
                if imageSelected == true {
                    
                    self.uploadEventImage()
                    
                } else {
                    
                    self.createEvent()
                }
            } else {
                
                SCLAlertView().showError("Oh no!", subTitle: "The event was not created because the required fields were left blank.")
            }
            
            animateFade(view: shadeView, alpha: 0)
            animateFade(view: createEventAlert, alpha: 0)
            
            inCreatePostMode = false
        }
    }
    
    // MARK: - Table View Functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        // We only need a single section for now.
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexOfEventSelected != indexPath.row {
            
            self.eventSelected = true
            self.indexOfEventSelected = indexPath.row
        } else {
            
            self.eventSelected = false
            self.indexOfEventSelected = -1
        }
        
        self.eventView.beginUpdates()
        self.eventView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == indexOfEventSelected && eventSelected == true {
        
            return 250.0
        }
        
        return 125.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Sort by popularity.
        events = events.sorted(by: { $0.count > $1.count })
        
        let event = events[indexPath.row]
        
        if let cell = eventView.dequeueReusableCell(withIdentifier: "event") as? EventCell {
            
            if let img = BoardVC.imageCache.object(forKey: event.imageURL as NSString) {
                
                cell.configureCell(event: event, img: img)
                return cell
                
            } else {
                
                cell.configureCell(event: event)
                return cell
            }
            
        } else {
            
            return EventCell()
        }
    }
    
    // MARK: - Text Field Functions
    
    // This function is called as soon as the user clicks on the createEventTimeField.
    @IBAction func timeFieldEditing(_ sender: TextField) {
        
        // First, we intialize a datePicker variable.
        let datePickerView: UIDatePicker = UIDatePicker()
        
        // This sets the format for the datepicker. In this case, it will show both date and time.
        datePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        
        // This changes the first responder of the text field from the keyboard to the datePicker initialized above.
        sender.inputView = datePickerView
        
        // This adds a target that updates the contents of the text field to match whatever the user is selecting in the datePicker.
        datePickerView.addTarget(self, action: #selector(BoardVC.datePickerChanged(sender:)), for: UIControlEvents.valueChanged)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard.
        textField.resignFirstResponder()
        return true
    }
}
