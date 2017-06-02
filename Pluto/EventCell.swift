//
//  EventCell.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import EventKit
import Lottie
import UIKit

class EventCell: UITableViewCell {
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventTimeAndPlaceLabel: UILabel!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventPlutoImageView: UIImageView!
    @IBOutlet weak var eventCountLabel: UILabel!
    @IBOutlet weak var eventFriendsCollectionView: UICollectionView!
    
    // MARK: - VARIABLES
    
    var event: Event!
    var eventUserRef: FIRDatabaseReference!
    var userEventRef: FIRDatabaseReference!
    var calendar: EKCalendar!
    
    // Holds all the friend keys under the current event.
    var eventFriendKeys = [String]()
    
    /// Holds all the friends of the current user.
    var friends = [User]()
    
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(EventCell.changeCount))
        tap.numberOfTapsRequired = 2
        
        self.addGestureRecognizer(tap)
        
        eventFriendsCollectionView.delegate = self
        eventFriendsCollectionView.dataSource = self
    }
    
    func loadIndicator() {
        
        activityIndicator.center = self.eventImageView.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = .white
        self.contentView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func stopIndicator() {
        
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    // MARK: - CONFIGURATION
    
    func configureCell(event: Event, img: UIImage? = nil) {
        
        loadIndicator()
        
        self.event = event
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        eventUserRef = DataService.ds.REF_EVENTS.child(event.eventKey).child("users").child(userID!)
        userEventRef = DataService.ds.REF_CURRENT_USER.child("events").child(event.eventKey)
        self.eventTitleLabel.text = event.title
        self.eventTimeAndPlaceLabel.text = "\(event.timeStart)"
        self.eventCountLabel.text = "\(event.count)"
        
        /* Checks to see if the image is located in the cache. */
        
        if img != nil {
            
            /* If it is, just grab it and set the image view to the cached image. */
            
            
        } else {
            
            /* If it isn't, save it the cache. */
            print("Saving event to cache")
            
            let ref = FIRStorage.storage().reference(forURL: event.imageURL)
            
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    /* ERROR: Unable to download photo from Firebase storage. */
                                    
                } else {
                    
                    /* SUCCESS: Image downloaded from Firebase storage. */
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            self.eventImageView.image = img
                            
                            BoardController.imageCache.setObject(img, forKey: event.imageURL as NSString) // Save to image cache.
                        }
                    }
                }
            })
        }
        
        userEventRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let _ = snapshot.value as? NSNull {
                
                self.eventPlutoImageView.image = UIImage(named: "ship-faded")
                
            } else {
                
                self.eventPlutoImageView.image = UIImage(named: "ship-yellow")
            }
        })
        
        stopIndicator()
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
    
    // MARK: - FIREBASE
    
    /**
     *  Uses the keys received from under the current user data reference to find and grab the data relating to the keys.
     */
    func grabEventFriends(userFriendKeys: [String]) {
                
        DataService.ds.REF_EVENTS.child(event.eventKey).child("users").observe(.value, with: { (snapshot) in
            
            self.eventFriendKeys = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    
                    for userFriendKey in userFriendKeys {
                        
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
        
        loadIndicator()
        
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
            self.eventFriendsCollectionView.reloadData()
            self.stopIndicator()
        })
    }
}

extension EventCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
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
        
        return CGSize(width: 50, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        /* Set the initial state of the cell. */
        let transform = CATransform3DTranslate(CATransform3DIdentity, 0, 250, 0)
        cell.layer.transform = transform
        
        /* Animation to change the state of the cell. */
        UIView.animate(withDuration: 0.8) {
            
            cell.layer.transform = CATransform3DIdentity
        }
    }
}

