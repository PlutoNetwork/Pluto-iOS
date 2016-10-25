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
    
    // MARK: - Outlets
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventTimeLabel: UILabel!
    @IBOutlet weak var eventDescriptionTextView: UITextView!
    @IBOutlet weak var eventCreatorLabel: UILabel!
    @IBOutlet weak var eventImageView: UIImageView!    
    @IBOutlet weak var eventPlutoImageView: UIImageView!
    @IBOutlet weak var eventPlutoCountLabel: UILabel!
    
    // MARK: - Variables
    var event: Event!
    var userEventRef: FIRDatabaseReference!
    var calendar: EKCalendar!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        eventPlutoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(EventCell.changePluto)))
    }
    
    func configureCell(event: Event, img: UIImage? = nil) {
        
        self.event = event
        
        userEventRef = DataService.ds.REF_CURRENT_USER.child("events").child(event.eventKey)
        
        self.eventTitleLabel.text = event.title
        self.eventTimeLabel.text = event.time
        self.eventCreatorLabel.text = "by \(event.creator)"
        self.eventPlutoCountLabel.text = "\(event.count)"
        
        if img != nil {
            
            self.eventImageView.image = img
            
        } else {
            
            let ref = FIRStorage.storage().reference(forURL: event.imageURL)
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    // Error! Unable to download photo from Firebase storage.
                                    
                } else {
                    
                    // Image successfully downloaded from Firebase storage.
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            self.eventImageView.image = img
                            
                            // Save to image cache (globally declared in BoardVC)
                            BoardVC.imageCache.setObject(img, forKey: event.imageURL as NSString)
                            
                        }
                    }
                }
            })
        }
        
        userEventRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let _ = snapshot.value as? NSNull {
                
                self.eventPlutoImageView.image = UIImage(named: "rocket-faded")
                
            } else {
                
                self.eventPlutoImageView.image = UIImage(named: "rocket")
            }
        })
    }
    
    func changePluto() {
        
        userEventRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let _ = snapshot.value as? NSNull {
                
                self.eventPlutoImageView.image = UIImage(named: "rocket")
                self.event.adjustCount(addToCount: true)
                self.userEventRef.setValue(true)
                self.syncToCalender(add: true)
                
            } else {
                
                self.eventPlutoImageView.image = UIImage(named: "rocket-faded")
                self.event.adjustCount(addToCount: false)
                self.userEventRef.removeValue()
                self.syncToCalender(add: false)
            }
        })
    }
    
    func syncToCalender(add: Bool) {
        
        let eventStore = EKEventStore()
        
        if EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized {
            
            eventStore.requestAccess(to: .event, completion: { (granted, error) in
            
                if error != nil {
                    
                    // Code if we get permission.
                    print("PERMISSION GRANTED")
                    
                    if add {
                        
                        let newEvent = EKEvent(eventStore: eventStore)
                        
                        newEvent.title = self.event.title
                        
                        // let strTime = "2016-10-27 19:29:50 +0000"
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                        let newEventTime = formatter.date(from: self.event.time)
                        
                        newEvent.startDate = newEventTime!
                        newEvent.endDate = newEventTime!
                        newEvent.location = self.event.location
                        newEvent.calendar = eventStore.defaultCalendarForNewEvents
                        
                        do {
                            
                            try eventStore.save(newEvent, span: .thisEvent)
                            print("EVENT ADDED")
                            print(newEvent.title)
                            print(newEvent.startDate)
                            print(newEvent.endDate)
                            
                        } catch {
                            
                            print("OH NO")
                        }
                    }
                    
                } else {
                    
                    print("ERORR")
                }
            })
            
        } else {
            
            // Code if we already have permission.
            
            if add {
                
                let newEvent = EKEvent(eventStore: eventStore)
                
                newEvent.title = self.event.title
                
                // let strTime = "2016-10-27 19:29:50 +0000"
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                let newEventTime = formatter.date(from: self.event.time)
                
                newEvent.startDate = newEventTime!
                newEvent.endDate = newEventTime!
                newEvent.location = self.event.location
                newEvent.calendar = eventStore.defaultCalendarForNewEvents
                
                do {
                    
                    try eventStore.save(newEvent, span: .thisEvent)
                    print("EVENT ADDED")
                    print(newEvent.title)
                    print(newEvent.startDate)
                    print(newEvent.endDate)
                    
                } catch {
                    
                    print("OH NO")
                }
            }
        }
    }
}
