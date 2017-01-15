//
//  ProfileVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class ProfileController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var friendsView: UICollectionView!
    @IBOutlet weak var eventsView: UITableView!
    
    // MARK: - VARIABLES
    
    let navigationBarTitle = UILabel()
    var navigationBarSettingsButton = UIBarButtonItem()
    var navigationBarSearchButton = UIBarButtonItem()
    
    /// Holds all the event keys under the current user.
    var userEventKeys = [String]()
    
    // Holds all the friend keys under the current user.
    var userFriendKeys = [String]()
    
    /// Holds all the event data received from Firebase.
    var events = [Event]()
    
    /// Holds all the user's friend data received from Firebase.
    var friends = [User]()
    
    // MARK: - VIEW
    
    override func viewWillAppear(_ animated: Bool) {
        
        /* Navigation bar customization. */
        self.navigationController?.setNavigationBarHidden(false, animated: true) // Presents the navigation bar.
        self.parent?.navigationItem.titleView = nil // Clears the logo.
        self.parent?.navigationItem.title = "Profile" // Sets the title of the navigation bar.
        self.navigationController?.navigationBar.tintColor = UIColor.white // Turns the contents of the navigation bar white.
        
        /* Search button */
        navigationBarSearchButton = UIBarButtonItem(image: UIImage(named: "ic-search"), style: .plain, target: self, action: #selector(ProfileController.goToUserSearchScreen))
        navigationBarSearchButton.tintColor = UIColor.white
        self.parent?.navigationItem.leftBarButtonItem  = navigationBarSearchButton
        
        /* Settings button */
        navigationBarSettingsButton = UIBarButtonItem(image: UIImage(named: "ic-settings"), style: .plain, target: self, action: #selector(ProfileController.goToSettings))
        navigationBarSettingsButton.tintColor = UIColor.white
        self.parent?.navigationItem.rightBarButtonItem  = navigationBarSettingsButton
        
        grabUserFriends()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Initialization of the friends view. */
        friendsView.dataSource = self
        friendsView.delegate = self
        
        /* Shadow properties */
        friendsView.layer.shadowColor = SHADOW_COLOR.cgColor
        friendsView.layer.shadowOpacity = 0.6
        friendsView.layer.shadowRadius = 6.0
        friendsView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
        /* Needed for the shadow to take effect */
        friendsView.layer.masksToBounds = false
        friendsView.clipsToBounds = false
        
        /* Initialization of the events view. */
        eventsView.dataSource = self
        eventsView.delegate = self
        
        grabUserEvents()
        checkForRequests()
    }
    
    // MARK: - FIREBASE
    
    func checkForRequests() {
        
        DataService.ds.REF_CURRENT_USER_FRIENDS.observe(.value, with: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    
                    let value = snap.value

                    let check = value! as! Bool
                    
                    if check == false {
                        
                        self.grabPotentialFriendInfo(friendKey: key)
                    }
                }
            }            
        })
    }
    
    func grabPotentialFriendInfo(friendKey: String) {
        
        DataService.ds.REF_USERS.child(friendKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            let name = value?["name"] as? String
            let image = value?["image"] as? String
            
            self.downloadProfileImage(key: friendKey, name: name!, image: image!)
            
        })  { (error) in
            
            // Error!
            
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't find your school.")
        }
    }
    
    func downloadProfileImage(key: String, name: String, image: String) {
        
        /// Holds the event image grabbed from the cache.
        if let img = BoardController.imageCache.object(forKey: image as NSString) {
            
            /* SUCCESS: Loaded image from the cache. */
            
            self.presentRequest(key: key, name: name, image: img)
            
        } else {
            
            /* ERROR: Could not load the event image. */
            
            /* If it doesn't download from the cache for some reason, just download it from Firebase. */
            
            let ref = FIRStorage.storage().reference(forURL: image)
            
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    /* ERROR: Unable to download photo from Firebase storage. */
                    
                } else {
                    
                    /* SUCCESS: Image downloaded from Firebase storage. */
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            self.presentRequest(key: key, name: name, image: img)
                        }
                    }
                }
            })
        }
    }
    
    func presentRequest(key: String, name: String, image: UIImage) {
        
        let appearance = SCLAlertView.SCLAppearance (
            
            kCircleIconHeight: 55.0,
            showCircularIcon: true
        )
        
        let notice = SCLAlertView(appearance: appearance)
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        notice.addButton("Yes!") {
            
            /* The user has given permission to send a friend request. */
            
            let friendRef = DataService.ds.REF_USERS.child(key).child("friends").child(userID!)
            friendRef.setValue(true)
            
            let userRef = DataService.ds.REF_CURRENT_USER_FRIENDS.child(key)
            userRef.setValue(true)
        }
        
        notice.addButton("Nope") {
            
            /* The user has given permission to send a friend request. */
            
            let friendRef = DataService.ds.REF_USERS.child(key).child("friends").child(userID!)
            friendRef.removeValue()
        }
        
        notice.showInfo("Friend request!", subTitle: "Would you like to accept \(name)'s friend request?", closeButtonTitle: "Close", circleIconImage: image)
    }
    
    /**
     *  Checks what events belong to the current user.
     */
    func grabUserEvents() {
        
        DataService.ds.REF_CURRENT_USER_EVENTS.observe(.value, with: { (snapshot) in
            
            self.userEventKeys = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    self.userEventKeys.append(key) // Add the key to the keys array.
                }
            }
            
            self.grabEventData() // We call this here because it needs to happen AFTER the keys array is filled.
        })
    }
    
    /**
     *  Uses the keys received from under the current board's data reference to find and grab the data relating to the keys.
     */
    func grabEventData() {
        
        DataService.ds.REF_EVENTS.observe(.value, with: { (snapshot) in
            
            self.events = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        
                        for userEventKey in self.userEventKeys {
                            
                            if key == userEventKey {
                                
                                /* The event belongs under this board. */
                                
                                let event = Event(eventKey: key, eventData: eventDict) // Format the data using the Event model.
                                
                                self.events.append(event) // Add the event to the events array.
                                
                                break // We no longer need to check if the key matches another event.
                            }
                        }
                    }
                }
            }
            
            self.events = self.events.sorted(by: { $0.timeStart.compare($1.timeStart) == ComparisonResult.orderedAscending }) // Sorts the array by how close the event is time-wise.
            self.eventsView.reloadData()
        })
    }
    
    /**
     *  Checks what friends belong to the current user.
     */
    func grabUserFriends() {
        
        DataService.ds.REF_CURRENT_USER_FRIENDS.observeSingleEvent(of: .value, with: { (snapshot) in
          
            self.userFriendKeys = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    
                    let value = snap.value
                    
                    let check = value! as! Bool
                    
                    if check == true {
                        
                        self.userFriendKeys.append(key) // Add the key to the keys array.
                    }
                }
            }
            
            self.grabFriendData()
        })
    }
    
    /**
     *  Uses the keys received from under the current user data reference to find and grab the data relating to the keys.
     */
    func grabFriendData() {
        
        DataService.ds.REF_USERS.observe(.value, with: { (snapshot) in
            
            self.friends = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let friendDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        
                        for userFriendKey in self.userFriendKeys {
                            
                            if key == userFriendKey {
                                
                                /* The event belongs under this user. */
                                
                                let friend = User(friendKey: key, friendData: friendDict) // Format the friend using the User model.
                                
                                self.friends.append(friend) // Add the friend to the friends array.
                                
                                break // We no longer need to check if the key matches another user.
                            }
                        }
                    }
                }
            }
            
            self.friends = self.friends.sorted(by: { $0.name > $1.name }) // Sorts the array by the number of people going to the event.
            self.friendsView.reloadData()
        })
    }
        
    // MARK: - TRANSITION
    
    func goToUserSearchScreen() {
        
        self.performSegue(withIdentifier: "showUserSearch", sender: self)
    }
    
    func goToSettings() {
        
        self.performSegue(withIdentifier: "showSettings", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showDetails" {
            
            let destinationController: DetailController = segue.destination as! DetailController
            
            if let indexPath = self.eventsView.indexPathForSelectedRow {
                
                destinationController.event = events[indexPath.row] // Passes the event to the detail screen.
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
}

extension ProfileController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let friend = friends[indexPath.row]
        
        if let friendCell = collectionView.dequeueReusableCell(withReuseIdentifier: "friend", for: indexPath) as? FriendCell {
                        
            if let img = BoardController.imageCache.object(forKey: friend.image as NSString) {
                
                friendCell.configureCell(friend: friend, img: img)
                return friendCell
                
            } else {
                
                friendCell.configureCell(friend: friend)
                return friendCell
            }
            
        } else {
            
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 120, height: 120)
    }
}

extension ProfileController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return 140.0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return events.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.performSegue(withIdentifier: "showDetails", sender: self)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        events = events.sorted(by: { ($0.count) > ($1.count)}) // Sort by popularity.

        let event = events[indexPath.row]

        if let cell = eventsView.dequeueReusableCell(withIdentifier: "event") as? EventCell {

            if let img = BoardController.imageCache.object(forKey: event.imageURL as NSString) {

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
