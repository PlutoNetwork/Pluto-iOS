//
//  EventCell.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import EventKit
import UIKit

class EventCell: UITableViewCell {
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventTimeAndPlaceLabel: UILabel!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventPlutoImageView: UIImageView!
    @IBOutlet weak var eventPlutoCountLabel: UILabel!
    
    // MARK: - VARIABLES
    
    var event: Event!
    var eventUserRef: FIRDatabaseReference!
    var userEventRef: FIRDatabaseReference!
    var calendar: EKCalendar!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(EventCell.changeCount))
        
        eventPlutoImageView.addGestureRecognizer(tap)
    }
    
    // MARK: - CONFIGURATION
    
    func configureCell(event: Event, img: UIImage? = nil) {
        
        self.event = event
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        eventUserRef = DataService.ds.REF_EVENTS.child(event.eventKey).child("users").child(userID!)
        userEventRef = DataService.ds.REF_CURRENT_USER.child("events").child(event.eventKey)
        self.eventTitleLabel.text = event.title
        self.eventTimeAndPlaceLabel.text = "\(event.location)  •  \(event.time)"
        self.eventPlutoCountLabel.text = "\(event.count)"
        
        /* Checks to see if the image is located in the cache. */
        
        if img != nil {
            
            /* If it is, just grab it and set the image view to the cached image. */
            self.eventImageView.image = img
            
        } else {
            
            /* If it isn't, save it the cache. */
            
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
                    
                    /* SUCCESS: We have access to modify the user's calendar. */
                    
                    if add {
                        
                        self.calendarCall(calEvent: eventStore)
                    }
                    
                } else {
                    
                    /* ERROR: Something went wrong and the user's calendar could not be accessed. */
                    
                    print(error.debugDescription)
                }
            })
            
        } else {
            
            // Code if we already have permission.
            
            if add {
                
                calendarCall(calEvent: eventStore)
            }
        }
    }
    
    func calendarCall(calEvent: EKEventStore){
        
        let newEvent = EKEvent(eventStore: calEvent)
        
        newEvent.title = self.event.title //Sets event title
        
        //Formats the date and time to be useable by iOS calendar app
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.short
        let newEventTime = formatter.date(from: self.event.time)
        
        newEvent.startDate = newEventTime! // Sets start date and time for event
        newEvent.endDate = newEventTime! // Sets end date and time for event
        newEvent.location = self.event.location // Copies location into calendar
        newEvent.calendar = calEvent.defaultCalendarForNewEvents // Copies event into calendar
        newEvent.notes = self.event.description // Copies event description into calendar
        
        do {
            
            //Saves event to calendar
            try calEvent.save(newEvent, span: .thisEvent)
            
        } catch {
            
            print("OH NO")
        }
    }
}
