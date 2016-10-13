//
//  EventCell.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class EventCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    @IBOutlet weak var eventTimeLabel: UILabel!
    @IBOutlet weak var eventDescriptionTextView: UITextView!
    @IBOutlet weak var eventCreatorLabel: UILabel!
    @IBOutlet weak var eventImageView: UIImageView!
    
    @IBOutlet weak var eventPlutoImageView: UIImageView!
    @IBOutlet weak var eventPlutoCountLabel: UILabel!
    
    // MARK: - Variables
    var event: Event!
    var userEventRef: FIRDatabaseReference!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        eventPlutoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(EventCell.changePluto)))
    }
    
    func configureCell(event: Event, img: UIImage? = nil) {
        
        self.event = event
        
        userEventRef = DataService.ds.REF_CURRENT_USER.child("events").child(event.eventKey)
        
        self.eventTitleLabel.text = event.title
        self.eventLocationLabel.text = event.location
        self.eventTimeLabel.text = event.time
        self.eventDescriptionTextView.text = event.description
        self.eventCreatorLabel.text = event.creator
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
                
                self.eventPlutoImageView.image = UIImage(named: "unstar")
                
            } else {
                
                self.eventPlutoImageView.image = UIImage(named: "star")
            }
        })
    }
    
    func changePluto() {
        
        userEventRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let _ = snapshot.value as? NSNull {
                
                self.eventPlutoImageView.image = UIImage(named: "star")
                self.event.adjustCount(addToCount: true)
                self.userEventRef.setValue(true)
                
            } else {
                
                self.eventPlutoImageView.image = UIImage(named: "unstar")
                self.event.adjustCount(addToCount: false)
                self.userEventRef.removeValue()
            }
        })
    }
}
