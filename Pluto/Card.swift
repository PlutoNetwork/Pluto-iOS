//
//  Card.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 11/24/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class Card: UIView {
    
    // MARK: - Outlets
    
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitle: UILabel!
    
    
    // MARK: - Variables
    
    /// Holds all the event data received from Firebase.
    var events = [Event]()
    
    var currentEvent: Event!
    
    // MARK: - Inspectables
    
    @IBInspectable var cornerRadius: CGFloat = 3.0 {
        didSet {
            
            setupView()
        }
    }
    
    // MARK: - Start
    
    override func awakeFromNib() {
        
        setupView()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        setupView()
    }
    
    func setupView() {
        
        self.layer.borderWidth = 1.0
        self.layer.borderColor = BORDER_COLOR.cgColor
        
        self.setNeedsLayout()
    }
    
    // MARK: - Firebase
    
    func grabCurrentBoardID() {
        
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            if value?["board"] as? String != nil {
                
                let currentBoardID = value?["board"] as? String
                self.setEvents(boardKey: currentBoardID!)
            }
        })
    }
    
    func setEvents(boardKey: String) {
        
        DataService.ds.REF_BOARDS.child(boardKey).child("events").observe(.value, with: { (snapshot) in
            
            self.events = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        let event = Event(eventKey: key, eventData: eventDict, boardKey: boardKey)
                        self.events.append(event)
                    }
                }
            }
            
//            self.eventView.reloadData()
        })
    }
    
    func setCard() {
        
        currentEvent = events[0]
        eventImageView.image = currentEvent.
    }
}
