//
//  BoardVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import FoldingTabBar
import UIKit

class BoardVC: UIViewController, UITableViewDataSource, UITableViewDelegate, YALTabBarDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var schoolNameLabel: UILabel!
    @IBOutlet weak var eventView: UITableView!
    @IBOutlet weak var createEventAlert: UIView!
    @IBOutlet weak var createEventTitleField: TextField!
    
    // MARK: - Variables
    
    /// Holds all the event data received from Firebase.
    var events = [Event]()
    
    /// Dims the screen when an alert pops up so the alert can stand out more.
    var shadeView: UIView!

    // MARK: - View Functions
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Grabs the email and password saved in a previous instance if the user already exists.
        let userDefaults = UserDefaults.standard
        
        // Checks to see if there is an email saved.
        if (userDefaults.string(forKey: "email") == nil) && (userDefaults.string(forKey: "board") == nil) {
            
            transitionToLogin()
        } else {
            
            setBoardTitle()
            setEvents()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initializes the table view that holds all the events.
        eventView.delegate = self
        eventView.dataSource = self
        
        shadeView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        shadeView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        shadeView.layer.zPosition = 1
        createEventAlert.layer.zPosition = 2
        self.view.addSubview(shadeView)
        shadeView.alpha = 0
    }
    
    // MARK: - Button Actions
    
    @IBAction func postEventButtonAction(_ sender: AnyObject) {
        
        print("Clicked")
        AnimationEngine.animateToPosition(view: createEventAlert, position: CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/2 + 1000))
    }
    
    // MARK: - Firebase

    func createEvent(boardKey: String, newEventTitle: String, newEventTime: String) {
        
        let event: Dictionary<String, AnyObject> = [
            
            "title": newEventTitle as AnyObject,
        ]
        
        let newEvent = DataService.ds.REF_BOARDS.child(boardKey).child("events").childByAutoId()
        newEvent.setValue(event)
    }
    
    func setBoardTitle() {
        
        let userDefaults = UserDefaults.standard
        
        DataService.ds.REF_BOARDS.child(userDefaults.string(forKey: "board")!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            
            let value = snapshot.value as? NSDictionary
            
            self.schoolNameLabel.text = (value?["title"] as? String)?.uppercased()
            
        }) { (error) in
            
            // Error!
        }
    }
    
    func setEvents() {
        
        let userDefaults = UserDefaults.standard
        
        DataService.ds.REF_BOARDS.child(userDefaults.string(forKey: "board")!).child("events").observe(.value, with: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
         
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
         
                        let key = snap.key
                        let event = Event(eventKey: key, eventData: eventDict)
                        self.events.append(event)
                    }
                }
            }
         
            self.eventView.reloadData()
        })
    }
    
    // MARK: - Helpers

    /**
     
     Function that allows transition to the login screen.
     
     */
    func transitionToLogin() {
        
        tabBarController?.selectedIndex = 1
    }
    
    // MARK: - Tab Bar Functions
    
    func tabBarDidSelectExtraRightItem(_ tabBar: YALFoldingTabBar) {
        
        shadeView.alpha = 1.0
        
        AnimationEngine.animateToPosition(view: createEventAlert, position: CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/2))
    }
    
    // MARK: - Table View Functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let event = events[indexPath.row]
        
        if let cell = eventView.dequeueReusableCell(withIdentifier: "event") as? EventCell {
            
            cell.configureCell(event: event)
        
            return cell
            
        } else {
            
            return EventCell()
        }
    }
}
