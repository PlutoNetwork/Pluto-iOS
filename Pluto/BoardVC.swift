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
    
    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
        
        // This function is called BEFORE the view loads.
        
        grabCurrentBoardID()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Initializes the table view that holds all the events.
        eventView.delegate = self
        eventView.dataSource = self
    }
    
    // MARK: - Button Actions
    
    @IBAction func createEventButtonAction(_ sender: AnyObject) {
        
        switchController(controllerID: "Create")
    }
    
    // MARK: - Firebase
    
    func grabCurrentBoardID() {
        
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
          
            let value = snapshot.value as? NSDictionary
            
            let currentBoardID = value?["board"] as? String
            self.setBoardTitle(boardKey: currentBoardID!)
            self.setEvents(boardKey: currentBoardID!)
        })
    }
    
    func setBoardTitle(boardKey: String) {
        
        DataService.ds.REF_BOARDS.child(boardKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            
            let value = snapshot.value as? NSDictionary
            
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
    
    func dismissKeyboard() {
        
        createEventTitleField.resignFirstResponder()
        createEventLocationField.resignFirstResponder()
        createEventTimeField.resignFirstResponder()
        createEventDescriptionField.resignFirstResponder()
    }
    
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
        
        // Didn't use the switchController function because we have to pass data into the next viewController.
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Details") as! DetailsVC
        
        controller.eventKey = events[indexPath.row].eventKey
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 140.0
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
