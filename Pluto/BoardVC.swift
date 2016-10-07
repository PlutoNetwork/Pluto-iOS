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
    @IBOutlet var headerView: UIView!
    @IBOutlet weak var eventView: UITableView!
    @IBOutlet weak var createEventAlert: UIView!
    
    // MARK: - Variables
    
    var events = [Event]()
    
    var shadeView: UIView!
    
    var newEventTime: String!
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventView.delegate = self
        eventView.dataSource = self
        
        findUserBoardAndSetTitle()
        
        shadeView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        shadeView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        shadeView.layer.zPosition = 1
        createEventAlert.layer.zPosition = 2
        self.view.addSubview(shadeView)
        shadeView.alpha = 0
    }
    
    // MARK: - Firebase
    
    func findUserBoardAndSetTitle() {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        DataService.ds.REF_USERS.child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            
            let value = snapshot.value as? NSDictionary
            
            let currentBoardKey = value?["board"] as! String
            
            self.setBoardTitle(boardKey: currentBoardKey)
            self.setEvents(boardKey: currentBoardKey)
            
        }) { (error) in
            
            // Error!
            
            logger.error(error.localizedDescription)
            
        }
    }
    
    func getKeyAndCreateEvent(newEventTitle: String, newEventTime: String) {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        DataService.ds.REF_USERS.child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            
            let value = snapshot.value as? NSDictionary
            
            let currentBoardKey = value?["board"] as! String
            
            self.createEvent(boardKey: currentBoardKey, newEventTitle: newEventTitle, newEventTime: newEventTime)
            
        }) { (error) in
            
            // Error!
            
            logger.error(error.localizedDescription)
        }
    }

    func createEvent(boardKey: String, newEventTitle: String, newEventTime: String) {
        
        let event: Dictionary<String, AnyObject> = [
            
            "title": newEventTitle as AnyObject,
            "time": newEventTime as AnyObject,
            "rocket": false as AnyObject,
            "board": boardKey as AnyObject
            
        ]
        
        let newEvent = DataService.ds.REF_BOARDS.child(boardKey).child("events").childByAutoId()
        print(event)
        newEvent.setValue(event)
    }
    
    func setBoardTitle(boardKey: String) {
        
        DataService.ds.REF_BOARDS.child(boardKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            
            let value = snapshot.value as? NSDictionary
            
            logger.info("SCHOOL: \(value?["title"] as! String)")
            
            self.schoolNameLabel.text = (value?["title"] as? String)?.uppercased()
            
        }) { (error) in
            
            // Error!
            
            logger.error(error.localizedDescription)
        }
    }
    
    func setEvents(boardKey: String) {
        
        DataService.ds.REF_BOARDS.child(boardKey).child("events").observe(.value, with: { (snapshot) in
         
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
            
            if indexPath.row % 2 == 0 {
                
                cell.contentView.backgroundColor = ALTERNATE_BACKGROUND_COLOR
                
            } else {
                
                cell.contentView.backgroundColor = BLUE_BACKGROUND_COLOR
            }
            
            return cell
            
        } else {
            
            return EventCell()
        }
    }
}
