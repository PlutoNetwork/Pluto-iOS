//
//  ProfileVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class ProfileVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Outlets
    
//    @IBOutlet weak var profileImageView: RoundImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var friendsView: UICollectionView!
    
    // Buttons
    
    // MARK: - Variables
    
    /// Holds all the event data received from Firebase.
    var events = [Event]()
    
    /// Holds all the user's friend data received from Firebase.
    var friends = [User]()
    
    var holdBoardKey: String!
    
    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
        
        UIApplication.shared.isStatusBarHidden = true
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        grabCurrentBoardID()
        //setUserInfo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setFriends()
        
        friendsView.dataSource = self
        friendsView.delegate = self
        
//        eventView.dataSource = self
//        eventView.delegate = self
    }
    
    // MARK: - Button Actions
    
    @IBAction func settingsButton(_ sender: AnyObject) {
        
        self.performSegue(withIdentifier: "showSettings", sender: self)
    }
    
    // MARK: - Collection View Functions
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let friendKey = friends[indexPath.row].friendKey
        
        self.performSegue(withIdentifier: "showProfile", sender: friendKey)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let friend = friends[indexPath.row]
        
        if let friendCell = collectionView.dequeueReusableCell(withReuseIdentifier: "friend", for: indexPath) as? FriendCell {
            
            friendCell.configureCell(friend: friend)
            return friendCell
            
        } else {
            
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 120, height: 120)
    }
    
    // MARK: - Firebase
    
    func grabCurrentBoardID() {
        
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            let currentBoardID = value?["board"] as? String
//            self.findUserEvents(boardKey: currentBoardID!)
            self.holdBoardKey = currentBoardID
        })
    }
    
    func setEvents(userEvents: [String], boardKey: String) {
                
        DataService.ds.REF_BOARDS.child(boardKey).child("events").observeSingleEvent(of: .value, with: { (snapshot) in
            
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
            
//            self.eventView.reloadData()
        })
    }
    
    func setFriends() {
        
        DataService.ds.REF_CURRENT_USER.child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
          
            self.friends = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let friendDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        let friend = User(friendKey: key, friendData: friendDict)
                        
                        if friend.connected == true {
                            
                            self.friends.append(friend)
                        }
                    }
                }
            }
            
            self.friendsView.reloadData()
        })
    }
    
    func findUserEvents(boardKey: String) {
        
        let userEventRef = DataService.ds.REF_CURRENT_USER.child("events")
        
        userEventRef.observe(.value, with: { (snapshot) in
            
            var userEventKeys = [String]()
         
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    userEventKeys.append(key)
                    
                    self.setEvents(userEvents: userEventKeys, boardKey: boardKey)
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
                        
//                        self.profileImageView.image = img
                        
                        // Save to image cache
                        BoardController.imageCache.setObject(img, forKey: imageURL as NSString)
                    }
                }
            }
        })
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
    
    // MARK: - Table View Functions
    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        
//        return 1
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        
//        self.performSegue(withIdentifier: "showDetails", sender: self)
//    }
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        
//        return 140.0
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        
//        return events.count
//    }
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//        // Sort by popularity.
//        events = events.sorted(by: { ($0.count) > ($1.count)})
//        
//        let event = events[indexPath.row]
//        
//        if let cell = eventView.dequeueReusableCell(withIdentifier: "event") as? EventCell {
//            
//            if let img = BoardController.imageCache.object(forKey: event.imageURL as NSString) {
//                
//                cell.configureCell(event: event, img: img)
//                return cell
//                
//            } else {
//                
//                cell.configureCell(event: event)
//                return cell
//            }
//            
//        } else {
//            
//            return EventCell()
//        }
//    }
}
