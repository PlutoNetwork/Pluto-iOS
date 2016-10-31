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

                        self.calendarCall(calEvent: eventStore)
                    }
                    
                } else {
                    
                    print("ERORR")
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
        
        newEvent.startDate = newEventTime! //Sets start date and time for event
        newEvent.endDate = newEventTime! //Sets end date and time for event
        newEvent.location = self.event.location //Copies location into calendar
        newEvent.calendar = calEvent.defaultCalendarForNewEvents //Copies event into calendar
        newEvent.notes = self.event.description //Copies event description into calendar
        
        do {
            
            //Saves event to calendar
            try calEvent.save(newEvent, span: .thisEvent)

            
        } catch {
            
            print("OH NO")
        }
        
        //Opens calendar app after event is added
        UIApplication.shared.openURL(NSURL(string: "calshow://")! as URL) //added JMS http://stackoverflow.com/questions/29684423/open-calendar-from-swift-app
    }
}
