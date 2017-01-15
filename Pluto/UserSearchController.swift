//
//  UserSearchController.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 1/14/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import Firebase

class UserSearchController: UIViewController, UINavigationControllerDelegate {

    // MARK: - OUTLETS
    
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var usersView: UICollectionView!
    
    // MARK: - VARIABLES
    
    /// Holds all the event keys under the current board.
    var boardUserKeys = [String]()
    
    /// Holds the data for all the users under the current board.
    var users = [User]()
    
    /// Holds all the filtered users as the filtering function does its work.
    var filteredUsers = [User]()
    
    /// Tells when user is typing in the searchBar.
    var inSearchMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self // Initialization of the search bar.
        
        searchBar.enablesReturnKeyAutomatically = false // Allows user to hit return key if the bar is blank.
        
        /* Initialization of the collection view that holds all the user. */
        usersView.delegate = self
        usersView.dataSource = self
        
        grabBoardUsers()
    }
    
    // MARK: - FIREBASE
    
    /**
     *  Checks what users belong to the current board.
     */
    func grabBoardUsers() {
        
        DataService.ds.REF_CURRENT_BOARD_USERS.observe(.value, with: { (snapshot) in
            
            self.boardUserKeys = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    self.boardUserKeys.append(key) // Add the key to the keys array.
                }
            }
            
            self.grabFriendData() // We call this here because it needs to happen AFTER the keys array is filled.
        })
    }
    
    /**
     *  Uses the keys received from under the current user data reference to find and grab the data relating to the keys.
     */
    func grabFriendData() {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        DataService.ds.REF_USERS.observe(.value, with: { (snapshot) in
            
            self.users = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let friendDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        
                        for boardFriendKey in self.boardUserKeys {
                            
                            if key == boardFriendKey && key != userID {
                                
                                /* The event belongs under this user. */
                                
                                let user = User(friendKey: key, friendData: friendDict) // Format the friend using the User model.
                                
                                self.users.append(user) // Add the friend to the friends array.
                                
                                break // We no longer need to check if the key matches another user.
                            }
                        }
                    }
                }
            }
            
            //            self.friends = self.events.sorted(by: { $0..compare($1.time) == ComparisonResult.orderedAscending }) // Sorts the array by how close the event is time-wise.
            self.usersView.reloadData()
        })
    }
    
    func downloadProfileImage(potentialFriend: User) {
        
        /* We know the image is in the cache because the main board page handles caching. But for safety, we should check. */
        
        /// Holds the event image grabbed from the cache.
        if let img = BoardController.imageCache.object(forKey: potentialFriend.image as NSString) {
            
            /* SUCCESS: Loaded image from the cache. */
            
            self.presentRequest(potentialFriend: potentialFriend, image: img)
            
        } else {
            
            /* ERROR: Could not load the event image. */
            
            /* If it doesn't download from the cache for some reason, just download it from Firebase. */
            
            let ref = FIRStorage.storage().reference(forURL: potentialFriend.image)
            
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    /* ERROR: Unable to download photo from Firebase storage. */
                    
                } else {
                    
                    /* SUCCESS: Image downloaded from Firebase storage. */
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            self.presentRequest(potentialFriend: potentialFriend, image: img)
                        }
                    }
                }
            })
        }
    }
    
    func presentRequest(potentialFriend: User, image: UIImage) {
        
        let appearance = SCLAlertView.SCLAppearance (
            
            kCircleIconHeight: 55.0,
            showCircularIcon: true
        )
        
        let notice = SCLAlertView(appearance: appearance)
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        let potentialFriendKey = potentialFriend.friendKey
        let potentialFriendName = potentialFriend.name
        
        notice.addButton("Yes!") {
            
            /* The user has given permission to send a friend request. */
            
            let friendRef = DataService.ds.REF_USERS.child(potentialFriendKey).child("friends").child(userID!)
            friendRef.setValue(false)
        }
        
        notice.showInfo("Hey!", subTitle: "Would you like to send \(potentialFriendName!) a friend request?", closeButtonTitle: "No, I made a mistake!", circleIconImage: image)
    }
}

extension UserSearchController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if inSearchMode == true {
            
            return filteredUsers.count
        }
        
        return users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var user = users[indexPath.row]
        
        if inSearchMode == true {
            
            user = filteredUsers[indexPath.row]
        }
        
        if let userCell = collectionView.dequeueReusableCell(withReuseIdentifier: "friend", for: indexPath) as? FriendCell {
            
            if let img = BoardController.imageCache.object(forKey: user.image as NSString) {
                
                userCell.configureCell(friend: user, img: img)
                return userCell
                
            } else {
                
                userCell.configureCell(friend: user)
                return userCell
            }
            
        } else {
            
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var potentialFriend = users[indexPath.row]
        
        if inSearchMode == true {
            
            potentialFriend = filteredUsers[indexPath.row]
        }
        
        self.downloadProfileImage(potentialFriend: potentialFriend)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 120, height: 120)
    }
}

extension UserSearchController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == "" {
            
            inSearchMode = false // This means the user is NOT typing in the searchBar.
            
            usersView.reloadData()
            
        } else {
            
            inSearchMode = true // This means the user is typing in the searchBar.
            
            let searchBarText = searchBar.text?.uppercased()
            
            filteredUsers = users.filter({$0.name.uppercased().range(of: searchBarText!) != nil}) // Filters the list of events as the user types into a new array.
            
            usersView.reloadData() // Reloads the users view as the filtering occurs.
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        /* This function is called when the user clicks the return key while editing of the searchBar is enabled. */
        
        searchBar.resignFirstResponder() // Dismisses the keyboard for the search bar.
    }
}
