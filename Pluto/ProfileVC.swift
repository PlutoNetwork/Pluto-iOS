//
//  ProfileVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class ProfileVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var profileImageView: RoundImageView!
    @IBOutlet weak var eventView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    
    // Buttons
    
    // MARK: - Variables
    
    /// Holds all the event data received from Firebase.
    var events = [Event]()
    
    var eventSelected = false
    var indexOfEventSelected = -1
    
    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
                
        findUserEvents()
        setUserInfo()
        
        eventView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventView.dataSource = self
        eventView.delegate = self
    }
    
    // MARK: - Button Actions
    
    // MARK: - Firebase
    
    func setEvents(userEvents: [String]) {
        
        let userDefaults = UserDefaults.standard
        
        DataService.ds.REF_BOARDS.child(userDefaults.string(forKey: "board")!).child("events").observe(.value, with: { (snapshot) in
            
            self.events = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        let event = Event(eventKey: key, eventData: eventDict)
                        
                        if userEvents.contains(snap.key) {
                            
                            self.events.append(event)
                        }
                    }
                }
            }
            
            self.eventView.reloadData()
        })
    }
    
    func findUserEvents() {
        
        let userEventRef = DataService.ds.REF_CURRENT_USER.child("events")
        
        userEventRef.observe(.value, with: { (snapshot) in
            
            var userEventKeys = [String]()
         
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    userEventKeys.append(key)
                    
                    self.setEvents(userEvents: userEventKeys)
                }
            }
        })
    }
    
    func setUserInfo() {
        
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            if value?["image"] != nil {
                
                self.downloadProfileImage(imageURL: (value?["image"] as? String)!)
            }
            
            if value?["name"] != nil {
                
                self.nameLabel.text = (value?["name"] as? String)?.uppercased()
            } else {
                
                self.nameLabel.text = (value?["email"] as? String)?.uppercased()
            }
                        
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
    
    // MARK: - Helpers
    
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
        events = events.sorted(by: { ($0.count) > ($1.count)})
        
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
}
