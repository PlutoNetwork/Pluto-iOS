//
//  UserSearchController.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 1/14/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import Firebase
import MessageUI

class UserSearchController: UIViewController, UINavigationControllerDelegate {

    // MARK: - OUTLETS
    
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var usersView: UICollectionView!
    @IBOutlet weak var recArrayLabel: UILabel!
    
    // MARK: - VARIABLES
    
    var navigationBarInviteButton: UIBarButtonItem!
    
    /// Holds all the event keys under the current board.
    var boardUserKeys = [String]()
    
    /// Holds the data for all the users under the current board.
    var users = [User]()
    
    /// Holds all the filtered users as the filtering function does its work.
    var filteredUsers = [User]()
    
    /// Tells when user is typing in the searchBar.
    var inSearchMode = false
    
    /// Holds the key of the event that may be passed from the detail screen.
    var event = Event(board: String(), count: Int(), creator: String(), description: String(), imageURL: String(), location: String(), publicMode: Bool(), timeStart: String(), timeEnd: String(), title: String())
    
    /// Tells when user enters screen from details page.
    var inInviteMode = false
    
    var userInviteeKeys = [String]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        /* Navigation bar customization */
        self.navigationController?.setNavigationBarHidden(false, animated: true) // Keeps the navigation bar unhidden.
        self.navigationController?.navigationBar.backItem?.title = "" // Keeps the back button to a simple "<".
        self.navigationController?.navigationBar.tintColor = UIColor.white // Changes the content of the navigation bar to a white color.
        
        /* Checks the event for any data. If it contains data, it was passed from the create controller and means that the user has come to edit the event. */
        
        if event.title != "" {
            
            inInviteMode = true
        }
        
        /* Changes the post button to reflect editing or creating a new event. */
        
        if inInviteMode == true {
            
            /* Post button */
            navigationBarInviteButton = UIBarButtonItem(image: UIImage(named: "ic-check"), style: .plain, target: self, action: #selector(UserSearchController.sendInvite)) // Initializes an invite button for the navigation bar.
            navigationBarInviteButton.tintColor = UIColor.white // Changes the color of the invite button to white.
            self.navigationItem.rightBarButtonItem  = navigationBarInviteButton // Adds the invite button to the navigation bar.
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self // Initialization of the search bar.
        
        searchBar.enablesReturnKeyAutomatically = false // Allows user to hit return key if the bar is blank.
        
        /* Initialization of the collection view that holds all the user. */
        usersView.delegate = self
        usersView.dataSource = self
        
        if inInviteMode == true {
            
            SCLAlertView().showInfo("Hey!", subTitle: "Search for your Pluto invitees here. Emails of friends without the app can be entered as well.")
        }
        
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
            
            self.users = self.users.sorted(by: { $0.name > $1.name }) // Sorts the array by the number of people going to the event.
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
    
    func sendInvite() {
        
        let recipients = recArrayLabel.text?.components(separatedBy: ", ")
        
        sendEmail(recipients: recipients!)
    }
    
    /**
     *  Switches to the view controller specified by the parameter.
     *
     *  - Parameter controllerID: The ID of the controller to switch to.
     */
    func switchController(controllerID: String) {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: controllerID) as UIViewController
        self.present(vc, animated: true, completion: nil)
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
        
        if inInviteMode == true {
            
            userInviteeKeys.append(potentialFriend.friendKey)
            
            recArrayLabel.text = recArrayLabel.text! + "\(potentialFriend.email!), "
            
            inSearchMode = false
            
        } else {
            
            self.downloadProfileImage(potentialFriend: potentialFriend)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 120, height: 120)
    }
}

extension UserSearchController: MFMailComposeViewControllerDelegate {
    
    func sendEmail(recipients: [String]) {
        
        let mailBody = "<img src='https://raw.githubusercontent.com/PlutoNetwork/Pluto-iOS/master/Pluto/Assets.xcassets/pluto-logo-black.imageset/pluto-logo-black.png'><br><p>Hey! You've been invited to the following event: \(event.title) from \(event.timeStart) to \(event.timeEnd). It will be at \(event.location)."
        
        if MFMailComposeViewController.canSendMail() {
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(recipients)
            mail.setMessageBody(mailBody, isHTML: true)
                        
            present(mail, animated: true)
            
        } else {
            
            // show failure alert
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true)
        
        for key in userInviteeKeys {
            
            let ref = DataService.ds.REF_USERS.child(key).child("events").child(event.eventKey)
            ref.setValue(false)
        }
        
        switchController(controllerID: "Main")
    }
}

extension UserSearchController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let searchBarText = searchBar.text?.uppercased()
        
        if searchBarText == "" {
            
            inSearchMode = false // This means the user is NOT typing in the searchBar.
            
            usersView.reloadData()
            
        } else {
            
            inSearchMode = true // This means the user is typing in the searchBar.
            
            filteredUsers = users.filter({$0.name.uppercased().range(of: searchBarText!) != nil}) // Filters the list of events as the user types into a new array.
            
            filteredUsers = self.filteredUsers.sorted(by: { $0.name > $1.name }) // Sorts the array by the number of people going to the event.
            
            usersView.reloadData() // Reloads the users view as the filtering occurs.
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        /* This function is called when the user clicks the return key while editing of the searchBar is enabled. */
        
        recArrayLabel.text = recArrayLabel.text! + "\(searchBar.text!), "
        searchBar.text = ""
        inSearchMode = false
        usersView.reloadData()
        
        searchBar.resignFirstResponder() // Dismisses the keyboard for the search bar.
    }
}
