//
//  DetailsVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/16/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//


import UIKit
import EventKit
import Firebase
import MessageUI

class DetailController: UIViewController {

    // MARK: - OUTLETS
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var eventImageView: UIImageView!
    
    @IBOutlet weak var detailsView: UIView!
    
    @IBOutlet weak var eventTimeAndPlaceLabel: UILabel!
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventDescriptionTextView: UITextView!
    
    @IBOutlet weak var eventPlutoImageView: UIImageView!
    @IBOutlet weak var eventPlutoCountLabel: UILabel!
    
    @IBOutlet weak var friendsView: UICollectionView!
    
    // MARK: - VARIABLES
    
    var eventUserRef: FIRDatabaseReference!
    var userEventRef: FIRDatabaseReference!
    var calendar: EKCalendar!
    
    var navigationBarEditButton: UIBarButtonItem!
    
    // Holds all the friend keys under the current user.
    var userFriendKeys = [String]()
    
    // Holds all the friend keys under the current event.
    var eventFriendKeys = [String]()
    
    /// Holds all the friends of the current user.
    var friends = [User]()
    
    /// Holds the key of the event passed from the main board screen.
    var event = Event(board: String(), count: Int(), creator: String(), description: String(), imageURL: String(), location: String(), publicMode: Bool(), timeStart: String(), timeEnd: String(), title: String())
    
    var usersToNotify = [String]()
    
    // MARK: - VIEW
    
    override func viewWillAppear(_ animated: Bool) {
        
        /* Navigation bar customization. */
        self.navigationController?.setNavigationBarHidden(false, animated: true) // Keeps the navigation bar unhidden.
        self.navigationItem.title = "Event Details" // Sets the title of the navigation bar.
        self.navigationController?.navigationBar.backItem?.title = "" // Keeps the back button a simple "<".
        self.navigationController?.navigationBar.tintColor = UIColor.white // Turns the contents of the navigation bar white.
        
        /* The edit button should only show up if the user is the creator of the event. */
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        if userID == event.creator {
        
            navigationBarEditButton = UIBarButtonItem(image: UIImage(named: "ic-edit"), style: .plain, target: self, action: #selector(DetailController.editEvent)) // Initializes an edit button for the navigation bar.
            
            navigationBarEditButton.tintColor = UIColor.white // Changes the color of the post button to white.
            
            self.navigationItem.rightBarButtonItem  = navigationBarEditButton // Adds the edit button to the navigation bar.
        }        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.contentSize.height = self.view.frame.height + friendsView.frame.height
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Initialization of the friends collection view. */
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
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        eventUserRef = DataService.ds.REF_EVENTS.child(event.eventKey).child("users").child(userID!)
        userEventRef = DataService.ds.REF_CURRENT_USER.child("events").child(event.eventKey)

        userEventRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let _ = snapshot.value as? NSNull {
                
                self.eventPlutoImageView.image = UIImage(named: "ship-faded")
                
            } else {
                
                self.eventPlutoImageView.image = UIImage(named: "ship-yellow")
            }
        })
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(EventCell.changeCount))
        
        eventPlutoImageView.addGestureRecognizer(tap)
        
        setEventDetails()
        grabUserFriends()
    }
    
    @IBAction func inviteButtonAction(_ sender: Any) {
        
        self.performSegue(withIdentifier: "showSearch", sender: self)
    }

    // MARK: - HELPERS
    
    /**
     *  Segues to the edit event screen.
     */
    func editEvent() {
        
        let notice = SCLAlertView()
        
        notice.addButton("Email all invitees") { 
            
            self.updateUsers(delete: false)
        }
        
        notice.addButton("Delete event") { 
            
            let eventRef = DataService.ds.REF_EVENTS.child(self.event.eventKey)
            /* The user has given permission to delete the event. */
            eventRef.removeValue()
            DataService.ds.REF_CURRENT_USER_EVENTS.child(self.event.eventKey).removeValue()
            DataService.ds.REF_CURRENT_BOARD_EVENTS.child(self.event.eventKey).removeValue()
            
            self.updateUsers(delete: true)
        }
        
        notice.showEdit("Edit event", subTitle: "", closeButtonTitle: "Close")
    }
    
    func grabUsers(key: String) {
        
        let userRef = DataService.ds.REF_USERS.child(key)
        
        userRef.child("events").child(event.eventKey).removeValue()
        
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            let email = value?["email"] as? String
            
            if email != nil {
                
                self.usersToNotify.append(email!)
            }
            
        }) { (error) in
            
            // Error!
            
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't finish the request.")
        }
    }
    
    func updateUsers(delete: Bool) {
        
        DataService.ds.REF_EVENTS.child(self.event.eventKey).child("users").observe(.value, with: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for _ in snapshot {
                    
                    self.grabUsers(key: self.event.eventKey)
                }
            }
            
            self.sendEmail(delete: delete)
        })
    }
    
    /**
     *  Grabs the event image from the cache.
     */
    func downloadEventImage(imageURL: String) {
        
        /* We know the image is in the cache because the main board page handles caching. But for safety, we should check. */
        
        /// Holds the event image grabbed from the cache.
        if let img = BoardController.imageCache.object(forKey: imageURL as NSString) {
        
            /* SUCCESS: Loaded image from the cache. */
            
            self.eventImageView.image = img // Sets the event image to the one grabbed from the cache.
            
        } else {
            
            /* ERROR: Could not load the event image. */
            
            /* If it doesn't download from the cache for some reason, just download it from Firebase. */
            
            let ref = FIRStorage.storage().reference(forURL: event.imageURL)
            
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    /* ERROR: Unable to download photo from Firebase storage. */
                    
                } else {
                    
                    /* SUCCESS: Image downloaded from Firebase storage. */
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            self.eventImageView.image = img
                        }
                    }
                }
            })
        }
    }
    
    /**
     *
     *  Uses the event passed in from the main board screen to load the event details.
     */
    func setEventDetails() {
        
        self.downloadEventImage(imageURL: event.imageURL)
        
        self.eventTitleLabel.text = event.title
        self.eventTimeAndPlaceLabel.text = "\(event.location)  •  \(event.timeStart) - \(event.timeEnd)"
        self.eventDescriptionTextView.text = event.description
        self.eventPlutoCountLabel.text = "\(event.count)"
    }
    
    // MARK: - FIREBASE
    
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
            
            self.grabEventFriends()
        })
    }
    
    /**
     *  Uses the keys received from under the current user data reference to find and grab the data relating to the keys.
     */
    func grabEventFriends() {
        
        DataService.ds.REF_EVENTS.child(event.eventKey).child("users").observe(.value, with: { (snapshot) in
            
            self.eventFriendKeys = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    
                    for userFriendKey in self.userFriendKeys {
                        
                        if key == userFriendKey {
                            
                            self.eventFriendKeys.append(key)
                            
                            break
                        }
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
                        
                        for eventFriendKey in self.eventFriendKeys {
                            
                            if key == eventFriendKey {
                                
                                /* The event belongs under this user. */
                                
                                let friend = User(friendKey: key, friendData: friendDict) // Format the friend using the User model.
                                
                                self.friends.append(friend) // Add the friend to the friends array.
                                
                                break // We no longer need to check if the key matches another user.
                            }
                        }
                    }
                }
            }
            
            self.friends = self.friends.sorted(by: { $0.name > $1.name }) // Sorts the array by the name of the friend.
            self.friendsView.reloadData()
        })
    }
    
    // MARK: - HELPERS
    
    /**
     Switches to the view controller specified by the parameter.
     
     - Parameter controllerID: The ID of the controller to switch to.
     */
    func switchController(controllerID: String) {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: controllerID) as UIViewController
        self.present(vc, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showEditEvent" {
            
            let destinationController: CreateController = segue.destination as! CreateController
            
            destinationController.event = event // Passes the event to the edit screen.
        
        } else if segue.identifier == "showEventGallery" {
            
           // let destinationController: GalleryController = segue.destination as! GalleryController
            
           // destinationController.eventKey = event.eventKey // Passes the event key to the gallery screen.
            
        } else if segue.identifier == "showSearch" {
            
            let destinationController: UserSearchController = segue.destination as! UserSearchController
            
            destinationController.event = event // Passes the event to the user search screen.
        }
    }
    
    func changeCount() {
        
        userEventRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let _ = snapshot.value as? NSNull {
                
                self.eventPlutoImageView.image = UIImage(named: "ship-yellow")
                self.event.adjustCount(addToCount: true)
                self.eventUserRef.setValue(true)
                self.userEventRef.setValue(true)
                self.syncToCalendar(add: true)
                
            } else {
                
                self.eventPlutoImageView.image = UIImage(named: "ship-faded")
                self.event.adjustCount(addToCount: false)
                self.eventUserRef.removeValue()
                self.userEventRef.removeValue()
                self.syncToCalendar(add: false)
            }
        })
    }
    
    func syncToCalendar(add: Bool) {
        
        let eventStore = EKEventStore()
        
        if EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized {
            
            eventStore.requestAccess(to: .event, completion: { (granted, error) in
                
                if error != nil {
                    
                    /* ERROR: Something went wrong and the user's calendar could not be accessed. */
                    
                    print(error.debugDescription)
                    
                } else {
                    
                    /* SUCCESS: We have access to modify the user's calendar. */
                    
                    if add {
                        
                        DispatchQueue.main.async {
                            
                            self.calendarCall(calEvent: eventStore, add: true)
                        }
                    } else {
                        
                        DispatchQueue.main.async {
                            
                            self.calendarCall(calEvent: eventStore, add: false)
                        }
                    }
                }
            })
            
        } else {
            
            // Code if we already have permission.
            
            if add {
                
                calendarCall(calEvent: eventStore, add: true)
            } else {
                
                self.calendarCall(calEvent: eventStore, add: false)
            }
        }
    }
    
    func calendarCall(calEvent: EKEventStore, add: Bool){
        
        let newEvent = EKEvent(eventStore: calEvent)
        
        newEvent.title = self.event.title //Sets event title
        
        //Formats the date and time to be useable by iOS calendar app
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.short
        let newEventStartTime = formatter.date(from: self.event.timeStart)
        let newEventEndTime = formatter.date(from: self.event.timeEnd)
        
        newEvent.startDate = newEventStartTime! // Sets start date and time for event
        newEvent.endDate = newEventEndTime! // Sets end date and time for event
        newEvent.location = self.event.location // Copies location into calendar
        newEvent.calendar = calEvent.defaultCalendarForNewEvents // Copies event into calendar
        newEvent.notes = self.event.description // Copies event description into calendar
        
        if add {
            
            do {
                
                //Saves event to calendar
                try calEvent.save(newEvent, span: .thisEvent)
                
                let notice = SCLAlertView()
                
                notice.addButton("Go to calendar", action: {
                    
                    let date = newEvent.startDate as NSDate
                    
                    UIApplication.shared.openURL(NSURL(string: "calshow:\(date.timeIntervalSinceReferenceDate)")! as URL)
                })
                
                notice.showSuccess("Success", subTitle: "Event added to calendar.", closeButtonTitle: "Done")
                
            } catch {
                
                SCLAlertView().showError("Error!", subTitle: "Event not added; try again later.")
            }
            
        } else {
            
            let predicate = calEvent.predicateForEvents(withStart: newEvent.startDate, end: newEvent.endDate, calendars: nil)
            
            let eV = calEvent.events(matching: predicate) as [EKEvent]!
            
            if eV != nil {
                
                for i in eV! {
                    
                    if i.title == newEvent.title {
                        
                        do {
                            
                            try calEvent.remove(i, span: EKSpan.thisEvent, commit: true)
                            
                            SCLAlertView().showSuccess("Success", subTitle: "Event removed from calendar.")
                            
                        } catch {
                            
                            SCLAlertView().showError("Error!", subTitle: "Event not removed; try again later.")
                        }
                    }
                }
            }
        }
    }
}

extension DetailController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return friends.count
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
}

extension DetailController: MFMailComposeViewControllerDelegate {
    
    func sendEmail(delete: Bool) {
        
        var mailSubject = "About \(event.title)"
        var mailBody = "<h1>\(event.title)</h1><p>\(event.timeStart) - \(event.timeEnd)</p><p>\(event.location)</p><br><p>\(event.description)</p><br><br><br><p>ENTER MESSAGE HERE</p><br><h4>This email was sent from the Pluto Events Network. <img src='https://raw.githubusercontent.com/PlutoNetwork/Pluto-iOS/master/Pluto/Assets.xcassets/pluto-logo-black.imageset/pluto-logo-black.png'>"
        
        if delete {
            
            mailSubject = "\(event.title) has been canceled."
            mailBody = "<h1>\(event.title)</h1><p>\(event.timeStart) - \(event.timeEnd)</p><p>\(event.location)</p><br><p>\(event.description)</p><br><br><h4>This email was sent from the Pluto Events Network. <img src='https://raw.githubusercontent.com/PlutoNetwork/Pluto-iOS/master/Pluto/Assets.xcassets/pluto-logo-black.imageset/pluto-logo-black.png'>"
        }

        if MFMailComposeViewController.canSendMail() {
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(usersToNotify)
            mail.setSubject(mailSubject)
            mail.setMessageBody(mailBody, isHTML: true)
            
            present(mail, animated: true)
            
        } else {
            
            // show failure alert
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true)
        
        switchController(controllerID: "Main")
    }
}
