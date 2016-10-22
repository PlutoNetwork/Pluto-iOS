//
//  DetailsVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/16/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class DetailsVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: - Outlets
    
    @IBOutlet weak var eventImageView: RoundImageView!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    @IBOutlet weak var eventTimeLabel: UILabel!
    @IBOutlet weak var eventDescriptionTextView: UITextView!
    @IBOutlet weak var eventCreatorLabel: UILabel!
    
    @IBOutlet weak var friendsGoingLabel: UILabel!
    @IBOutlet weak var friendsView: UICollectionView!
    
    // MARK: - Variables
    
    var eventKey = String()
    var boardKey = String()
    var friends = [Friend]()
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        friendsView.dataSource = self
        friendsView.delegate = self
        
        grabCurrentBoardID()
    }
    
    // MARK: - Button Actions
    
    @IBAction func backButtonAction(_ sender: AnyObject) {
        
        switchController(controllerID: "Main")
    }
    
    // MARK: - Collection View Functions
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switchToProfile(creatorID: friends[indexPath.row].friendKey)
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
    
    func downloadEventImage(imageURL: String) {
        
        let ref = FIRStorage.storage().reference(forURL: imageURL)
        ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                // Error! Unable to download photo from Firebase storage.
                
            } else {
                
                // Image successfully downloaded from Firebase storage.
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        self.eventImageView.image = img
                        
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
            self.setEventDetails(currentBoardID: currentBoardID!)
            self.setFriends(boardKey: currentBoardID!)
            self.boardKey = currentBoardID!
        })
    }
    
    func setEventDetails(currentBoardID: String) {
        
        DataService.ds.REF_BOARDS.child(currentBoardID).child("events").child(eventKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            self.downloadEventImage(imageURL: (value?["imageURL"] as? String)!)
            
            self.eventTitleLabel.text = value?["title"] as? String
            self.eventLocationLabel.text = value?["location"] as? String
            self.eventTimeLabel.text = value?["time"] as? String
            self.eventDescriptionTextView.text = value?["description"] as? String
            self.eventCreatorLabel.text = value?["creator"] as? String
        })
    }
    
    func setFriends(boardKey: String) {
        
        DataService.ds.REF_CURRENT_USER.child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.friends = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let friendDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        let friend = Friend(friendKey: key, friendData: friendDict)
                        
                        if friend.connected == true {
                            
                            self.checkFriendEvent(friend: friend, boardKey: boardKey)
                        }
                    }
                }
            }            
        })
    }
    
    func checkFriendEvent(friend: Friend, boardKey: String) {
        
        DataService.ds.REF_USERS.child(friend.friendKey).child("events").observeSingleEvent(of: .value, with: { (snapshot) in
         
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if snap.key == self.eventKey {
                        
                        self.friends.append(friend)
                    }
                }
            }
            
            self.friendsView.reloadData()
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
    
    func switchToProfile(creatorID: String) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Friend") as! FriendVC
        
        controller.creatorID = creatorID
        controller.boardKey = boardKey
        
        self.present(controller, animated: true, completion: nil)
    }
}
