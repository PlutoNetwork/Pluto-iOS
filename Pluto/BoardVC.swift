//
//  BoardVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class BoardVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var schoolNameLabel: UILabel!
    @IBOutlet weak var searchPreview: UITableView!
    @IBOutlet weak var eventView: UITableView!
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
    
    /// Holds all the board titles from the CSV file.
    var users = [Friend]()
    /// Holds all the filtered board titles as the filtering function does its work.
    var filteredUsers = [Friend]()
    
    var holdBoardKey: String!
    
    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
        
        UIApplication.shared.isStatusBarHidden = false
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // This function is called BEFORE the view loads.
        grabCurrentBoardID()
        checkForRequests()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchPreview.delegate = self
        searchPreview.dataSource = self
        
        // Initializes the table view that holds all the events.
        eventView.delegate = self
        eventView.dataSource = self
    }
    
    // MARK: - Firebase
    
    func checkForRequests() {
        
        DataService.ds.REF_CURRENT_USER.child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
         
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                if let friendDict = snap.value as? Dictionary<String, AnyObject> {
                    
                    let key = snap.key
                    let friend = Friend(friendKey: key, friendData: friendDict)
                    
                        if friend.request == true {
                            
                            self.grabFriendInfo(friendKey: friend.friendKey)
                        }
                    }
                }
            }
        })
    }
    
    func grabUsers() {
        
        DataService.ds.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    
                }
            }
        })
    }
    
    func downloadProfileImage(friendKey: String, imageURL: String, name: String) {
        
        let ref = FIRStorage.storage().reference(forURL: imageURL)
        ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                // Error! Unable to download photo from Firebase storage.
                
            } else {
                
                // Image successfully downloaded from Firebase storage.
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        self.presentRequestNotice(friendID: friendKey, img: img, name: name)
                        
                        // Save to image cache (globally declared in BoardVC)
                        BoardVC.imageCache.setObject(img, forKey: imageURL as NSString)
                    }
                }
            }
        })
    }
    
    func grabCurrentBoardID() {
        
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
          
            let value = snapshot.value as? NSDictionary
            
            let currentBoardID = value?["board"] as? String
            self.setBoardTitle(boardKey: currentBoardID!)
            self.setEvents(boardKey: currentBoardID!)
            self.holdBoardKey = currentBoardID!
        })
    }
    
    func grabFriendInfo(friendKey: String) {
        
        DataService.ds.REF_USERS.child(friendKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            // Checks to see if the user has a set profile image.
            if value?["image"] != nil {
                
                if value?["name"] != nil {
                    
                    // Downloads the set profile image.
                    self.downloadProfileImage(friendKey: friendKey, imageURL: (value?["image"] as? String)!, name: (value?["name"] as? String)!)
                } else {
                    
                    self.downloadProfileImage(friendKey: friendKey, imageURL: (value?["image"] as? String)!, name: (value?["email"] as? String)!)
                }
            }
            
        })  { (error) in
            
            // Error!
            
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't find your school.")
        }
    }
    
    func setBoardTitle(boardKey: String) {
        DataService.ds.REF_BOARDS.child(boardKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            
            let value = snapshot.value as? NSDictionary
            
            self.navigationItem.title = (value?["title"] as? String)?.uppercased()
            self.schoolNameLabel.text = (value?["title"] as? String)?.uppercased()
            
        }) { (error) in
            
            // Error!
            
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't find your school.")
        }
    }
    
    func setEvents(boardKey: String) {
                
        DataService.ds.REF_BOARDS.child(boardKey).child("events").observe(.value, with: { (snapshot) in
            
            self.events = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        let event = Event(eventKey: key, eventData: eventDict, boardKey: boardKey)
                        self.events.append(event)
                    }
                }
            }
            
            self.eventView.reloadData()
        })
    }
        
    // MARK: - Helpers
    
    /**
     Dismisses the keyboard!
     
     Just put whatever textfields you want included here in the function.
     */
    func dismissKeyboard() {
        
        // Dissmisses the keybaord for these fields.
        createEventTitleField.resignFirstResponder()
        createEventLocationField.resignFirstResponder()
        createEventTimeField.resignFirstResponder()
        createEventDescriptionField.resignFirstResponder()
    }
    
    func presentRequestNotice(friendID: String, img: UIImage, name: String) {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        let appearance = SCLAlertView.SCLAppearance (
            
            kCircleIconHeight: 55.0,
            showCircularIcon: true
        )
        
        // Create an alert to inform the user that they actually have friends.
        let notice = SCLAlertView(appearance: appearance)
        let noticeViewIcon = img
        
        notice.addButton("Accept") {
            
            DataService.ds.REF_CURRENT_USER.child("friends").child(friendID).child("connected").setValue(true)
            DataService.ds.REF_CURRENT_USER.child("friends").child(friendID).child("request").setValue(false)
            
            DataService.ds.REF_USERS.child(friendID).child("friends").child(userID!).child("request").setValue(false)
            DataService.ds.REF_USERS.child(friendID).child("friends").child(userID!).child("connected").setValue(true)
        }
        
        notice.showInfo("Hey!", subTitle: "You have a friend request from \(name).", closeButtonTitle: "Deny", circleIconImage: noticeViewIcon)
        
        DataService.ds.REF_CURRENT_USER.child("friends").child(friendID).child("request").setValue(false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showDetails" {
            
            let destinationVC: DetailsVC = segue.destination as! DetailsVC
            
            if let indexPath = self.eventView.indexPathForSelectedRow {
             
                destinationVC.eventKey = events[indexPath.row].eventKey
            }
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
    
    // MARK: - Table View Functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        // We only need a single section for now.
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.eventView {
        
            self.performSegue(withIdentifier: "showDetails", sender: self)
        } else {
            
            print("Tapped")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if tableView == self.eventView {
        
            return 140.0
        } else {
            
            return 50.0
        }
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard.
        textField.resignFirstResponder()
        return true
    }
}
