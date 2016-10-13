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
    
    @IBOutlet weak var createEventAlert: UIView!
    @IBOutlet weak var createEventImageView: UIImageView!
    @IBOutlet weak var createEventTitleField: TextField!
    @IBOutlet weak var createEventLocationField: UITextField!
    @IBOutlet weak var createEventTimeField: TextField!
    @IBOutlet weak var createEventDescriptionField: UITextView!
    @IBOutlet weak var shadeView: UIView!
    
    // MARK: - Variables
    
    /// Holds all the event data received from Firebase.
    var events = [Event]()
    
    var inCreatePostMode = false
    
    var imagePicker: UIImagePickerController!
    
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    var imageSelected = false
    
    var eventSelected = false
    var indexOfEventSelected = -1
    
    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Grabs the email and password saved in a previous instance if the user already exists.
        let userDefaults = UserDefaults.standard
        
        // Checks to see if there is an email saved.
        if (userDefaults.string(forKey: "email") == nil) && (userDefaults.string(forKey: "board") == nil) {
            
            self.tabBarController?.selectedIndex = 2
        } else {
            
            setBoardTitle()
            setEvents()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dismisses the keyboard if the user taps anywhere on the screen.
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BoardVC.dismissKeyboard)))
        
        // Initializes the table view that holds all the events.
        eventView.delegate = self
        eventView.dataSource = self
        
        createEventTitleField.delegate = self
        createEventTimeField.delegate = self
        
        // Initializes the image picker.
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
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
    
    func tabBar(_ tabBar: YALFoldingTabBar, didSelectItemAt index: UInt) {
        
        print(index)
        
        if index == 1 {
            
            print("LOG OUT")
            
            try! FIRAuth.auth()?.signOut()
            
            SCLAlertView().showInfo("Goodbye!", subTitle: "You have been logged out.")
            
            // Transitions to the main board screen.
            // self.tabBarController?.selectedIndex = 2
        }
    }
    
    func tabBar(_ tabBar: YALFoldingTabBar, shouldSelectItemAt index: UInt) -> Bool {
        
        print(index)
        
        return true
    }
    
    // MARK: - Table View Functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexOfEventSelected != indexPath.row {
            
            self.eventSelected = true
            self.indexOfEventSelected = indexPath.row
        }
        else {
            
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
    
    @IBAction func timeFieldEditing(_ sender: TextField) {
        
        let datePickerView: UIDatePicker = UIDatePicker()
        
        datePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        
        sender.inputView = datePickerView
        
        datePickerView.addTarget(self, action: #selector(BoardVC.datePickerChanged(sender:)), for: UIControlEvents.valueChanged)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard.
        textField.resignFirstResponder()
        return true
    }
}
