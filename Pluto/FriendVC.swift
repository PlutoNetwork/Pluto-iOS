//
//  FriendVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/16/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit


class FriendVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var addBuddyButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var userProfileImageView: RoundImageView!
    @IBOutlet weak var friendsView: UICollectionView!
    @IBOutlet weak var eventView: UITableView!
    
    // MARK: - Variables
    
    /// Holds all the ID of the user who created the event.
    var creatorID = String()
    
    /// Holds all the event data received from Firebase.
    var events = [Event]()
    
    /// Holds all the user's friend data received from Firebase.
    var friends = [Friend]()
    
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    override func viewWillAppear(_ animated: Bool) {
        
        UIApplication.shared.isStatusBarHidden = true
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.title = "View Profile"
        self.navigationController?.navigationBar.backItem?.title = ""
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        setFriends()
        setUserInfo()
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendsView.delegate = self
        friendsView.dataSource = self
        
        // Initializes the event view.
        eventView.delegate = self
        eventView.dataSource = self
    }
    
    // MARK: - Button Actions
    
    @IBAction func backButtonAction(_ sender: AnyObject) {
        
        switchController(controllerID: "Main")
    }
    
    @IBAction func addBuddyButtonAction(_ sender: AnyObject) {
        
        sendBuddyRequest()
        
        UIView.animate(withDuration: 0.5) { 
            
            self.addBuddyButton.setImage(UIImage(named: "ic_done_white"), for: .normal)
        }
    }
    
    // MARK: - Collection View Functions
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.creatorID = friends[indexPath.row].friendKey
        setFriends()
        setUserInfo()
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
    
    /**
     Goes into Firebase storage to download the user's set profile image.
     
     - Parameter imageURL: A string that holds a reference to where the image is stored in the Firebase storage.
     */
    func downloadProfileImage(imageURL: String) {
        
        /// Uses the parameter (imageURL) to make a complete link to where the image is stored in the Firebase storage.
        let ref = FIRStorage.storage().reference(forURL: imageURL)
        
        // withMaxSize was computed in a tutorial online that found it to be ideal for the limit.
        ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                // Error! Unable to download photo from Firebase storage.
                SCLAlertView().showError("Oh no!", subTitle: "Pluto was unable to find your profile photo.")
                
                // Instead, set the profile image view to the profile placeholder image.
                self.userProfileImageView.image = UIImage(named: "profile_img_placeholder")
                
            } else {
                
                // Success! Image successfully downloaded from Firebase storage.
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        // Set the profile image view to the downloaded image.
                        self.userProfileImageView.image = img
                        
                        // Save to image cache (globally declared in BoardVC).
                        BoardVC.imageCache.setObject(img, forKey: imageURL as NSString)
                    }
                }
            }
        })
    }
    
    /**
     Grabs the events of the person who made the event.
     
     Adds the event keys stored in the user's data into an array.
     */
    func grabUserEvents(boardKey: String) {
        
        DataService.ds.REF_USERS.child(creatorID).child("events").observeSingleEvent(of: .value, with: { (snapshot) in
                        
            var userEventKeys = [String]()
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    userEventKeys.append(key)
                    
                    self.setEvents(userEventKeys: userEventKeys, boardKey: boardKey)
                }
            }
        })
    }
    
    func setFriends() {
        
        DataService.ds.REF_USERS.child(creatorID).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.friends = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let friendDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        let friend = Friend(friendKey: key, friendData: friendDict)
                    
                        if friend.connected == true {
                            
                            self.friends.append(friend)
                        }
                        
                        let userID = FIRAuth.auth()?.currentUser?.uid
                        
                        if friend.friendKey == userID! {
                            
                            self.addBuddyButton.setImage(UIImage(named: "ic_done_white"), for: .normal)
                            self.addBuddyButton.isUserInteractionEnabled = false
                        }
                    }
                }
            }
            
            self.friendsView.reloadData()
        })
    }
    
    /**
     Called when the user clicks the addBuddyButton.
     */
    func sendBuddyRequest() {
        
        // Adds the potential friend to the user's friends data and sets the value of the request key to false b/c the request was sent and has not yet been accepted.
        DataService.ds.REF_CURRENT_USER.child("friends").child(creatorID).child("connected").setValue(false)
        
        // Sets the request value under the same data reference as above to false.
        DataService.ds.REF_CURRENT_USER.child("friends").child(creatorID).child("request").setValue(false)
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        // Adds the current user to the potential friend's friends data and sets the value of the request key to true indicating a request has been sent.
        DataService.ds.REF_USERS.child(creatorID).child("friends").child(userID!).child("request").setValue(true)
        
        DataService.ds.REF_USERS.child(creatorID).child("friends").child(userID!).child("connected").setValue(false)
    }
    
    func setEvents(userEventKeys: [String], boardKey: String) {
        
        DataService.ds.REF_BOARDS.child(boardKey).child("events").observe(.value, with: { (snapshot) in
            
            self.events = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        let event = Event(eventKey: key, eventData: eventDict, boardKey:boardKey)
                        
                        if userEventKeys.contains(event.eventKey) {
                            
                            self.events.append(event)
                        }
                    }
                }
            }
            
            self.eventView.reloadData()
        })
    }
    
    func setUserInfo() {
        
        DataService.ds.REF_USERS.child(creatorID).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            let boardKey = (value?["board"] as? String)!
            
            self.grabUserEvents(boardKey: boardKey)
            
            // Checks to see if the user has a set profile image.
            if value?["image"] != nil {
                
                // Downloads the set profile image.
                self.downloadProfileImage(imageURL: (value?["image"] as? String)!)
            }
            
            if value?["name"] != nil {
                
                self.nameLabel.text = (value?["name"] as? String)?.uppercased()
                
            } else {
                
                self.nameLabel.text = (value?["email"] as? String)?.uppercased()
            }
            
            if value?["major"] != nil {
                
                self.majorLabel.text = (value?["major"] as? String)
                
            } else {
                
                self.majorLabel.alpha = 0
            }
            
        })  { (error) in
            
            // Error!
            
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't find your school.")
        }
    }
    
    // MARK: - Helpers
    
    func createActivityIndicator() {
        
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        view.addSubview(activityIndicator)
    }
    
    func startActivityIndicator() {
        
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func stopActivityIndicator() {
        
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
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
        
        // Didn't use the switchController function because we have to pass data into the next viewController.
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Details") as! DetailsVC
        
        //controller.eventKey = events[indexPath.row].eventKey
        
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
}
