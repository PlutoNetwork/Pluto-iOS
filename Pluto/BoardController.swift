//
//  BoardVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit
import BetterSegmentedControl
import Firebase
import FirebaseInstanceID
import FirebaseMessaging

class BoardController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var sortControlView: View!
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var eventsView: UITableView!
    
    // MARK: - VARIABLES
    
    let navigationBarTitle = UILabel()
    var navigationBarAddButton = UIBarButtonItem()
    var navigationBarSearchButton = UIBarButtonItem()
    
    /// Holds all event pictures.
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    /// Holds events.
    static var eventCache: NSCache<NSString, Event> = NSCache()
    
    /// Holds all the event keys under the current board.
    var boardEventKeys = [String]()
    
    /// Holds the data for all the events under the current board.
    var events = [Event]()
    
    /// Holds all the filtered board titles as the filtering function does its work.
    var filteredEvents = [Event]()
    
    var friendEvents = [Event]()
    
    /// Holds all the friend keys under the current user.
    var userFriendKeys = [String]()
    
    /// Tells when user is typing in the searchBar.
    var inSearchMode = false
    
    var inFriendMode = false
    
    var sunnyRefreshControl: YALSunnyRefreshControl!
    
    // MARK: - VIEW
    
    override func viewWillAppear(_ animated: Bool) {
        
        /* Navigation bar customization. */
        self.navigationController?.setNavigationBarHidden(false, animated: true) // Presents the navigation bar.
        
        /* Logo in the middle of the navigation bar */
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
        imageView.contentMode = .scaleAspectFit
        let image = UIImage(named: "logo")
        imageView.image = image
        self.parent?.navigationItem.titleView = imageView
        
        /* Search button */
        /* I've hidden this because I added the search bar to the screen. The reason I didn't just delete it was because there's a spacing problem with the other elements on the nav bar; if I delete this, the logo is off-center. */
        navigationBarSearchButton = UIBarButtonItem(image: UIImage(named: "ic-search"), style: .plain, target: self, action: #selector(BoardController.goToAddEventScreen))
        navigationBarSearchButton.tintColor = UIColor.clear
        self.parent?.navigationItem.leftBarButtonItem  = navigationBarSearchButton
         self.parent?.navigationItem.leftBarButtonItem?.isEnabled = false
        
        /* Add event button */
        navigationBarAddButton = UIBarButtonItem(image: UIImage(named: "ic-add-event"), style: .plain, target: self, action: #selector(BoardController.goToAddEventScreen))
        navigationBarAddButton.tintColor = UIColor.white
        self.parent?.navigationItem.rightBarButtonItem  = navigationBarAddButton
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        initializeSortControl()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self // Initialization of the search bar.
        
        searchBar.enablesReturnKeyAutomatically = false // Allows user to hit return key if the bar is blank.
        
        /* Initialization of the table view that holds all the events. */
        eventsView.delegate = self
        eventsView.dataSource = self
        
        setupRefreshControl()
        sunnyRefreshControl.beginRefreshing()

    }
    
    func setupRefreshControl() {
        
        sunnyRefreshControl = YALSunnyRefreshControl()
        sunnyRefreshControl.addTarget(self, action: #selector(BoardController.grabUserFriends), for: .valueChanged)
        sunnyRefreshControl.attach(to: eventsView)
    }
    
    // MARK: - FIREBASE
    
    /**
     *  Checks what events belong to the current board.
     */
    func grabBoardEvents() {
        
        DataService.ds.REF_CURRENT_BOARD_EVENTS.observe(.value, with: { (snapshot) in
            
            self.boardEventKeys = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    self.boardEventKeys.append(key) // Add the key to the keys array.
                }
            }
            
            self.grabEventData() // We call this here because it needs to happen AFTER the keys array is filled.
        })
    }
    
    /**
     *  Uses the keys received from under the current board's data reference to find and grab the data relating to the keys.
     */
    func grabEventData() {
        
        DataService.ds.REF_EVENTS.observe(.value, with: { (snapshot) in
            
            self.events = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        
                        for boardEventKey in self.boardEventKeys {
                            
                            if key == boardEventKey {
                                
                                /* The event belongs under this board. */
                                
                                let event = Event(eventKey: key, eventData: eventDict) // Format the data using the Event model.
                                
                                /* MICHAEL CHECK HERE */
                                
                                /* We have to do a check here to see if the event time has already passed. */
                                
                                /* For this comparison, do "if event.time.compare(currentTime) == .orderedDescending". The challenge is figuring out how to get the currentTime. */
                                
                                /* Once you figure it out, put the append statement in the if statement. */
                                
                                if event.publicMode == true {
                                
                                    self.checkFriendUnderEvent(event: event)
                                    
                                    self.events.append(event) // Add the event to the events array.
                                }
                                
                                break // We no longer need to check if the key matches another event.
                            }
                        }
                    }
                }
            }
            
            self.sortEvents(sortBy: "popular")
            self.eventsView.reloadData()
            self.sunnyRefreshControl.endRefreshing()
        })
    }
    
    func checkFriendUnderEvent(event: Event) {
        
        DataService.ds.REF_EVENTS.child(event.eventKey).child("users").observe(.value, with: { (snapshot) in
            
            self.friendEvents = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    
                    for userFriendKey in self.userFriendKeys {
                        
                        if key == userFriendKey {
                            
                            self.friendEvents.append(event)
                            
                            break
                        }
                    }
                }
            }
            
            self.friendEvents = self.friendEvents.sorted(by: { $0.timeStart.compare($1.timeStart) == ComparisonResult.orderedAscending }) // Sorts the array by how close the event is time-wise.
        })
    }
    
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
            
            self.grabBoardEvents()
        })
    }
    
    // MARK: - HELPERS
    
    /**
     *  Uses the BetterSegmentedControl library to configure a segmented switch.
     */
    func initializeSortControl() {
        
        let control = BetterSegmentedControl(
            
            frame: CGRect(x: 0, y: 0, width: sortControlView.frame.width, height: sortControlView.frame.height),
            titles: ["Upcoming", "Popular", "Friends"],
            index: 1,
            backgroundColor: VIEW_BACKGROUND_COLOR,
            titleColor: YELLOW_COLOR,
            indicatorViewBackgroundColor: YELLOW_COLOR,
            selectedTitleColor: VIEW_BACKGROUND_COLOR)
        
        control.titleFont = UIFont(name: "Lato-Regular", size: 15.0)!
        control.selectedTitleFont = UIFont(name: "Lato-Bold", size: 15.0)!
        
        control.addTarget(self, action: #selector(BoardController.navigationSegmentedControlValueChanged(_:)), for: .valueChanged)
        
        sortControlView.addSubview(control)
    }
    
    /**
     *  #GATEWAY
     *
     *  Sorts events.
     */
    func navigationSegmentedControlValueChanged(_ sender: BetterSegmentedControl) {
        
        if sender.index == 0 {
            
            sortEvents(sortBy: "upcoming")
            
        } else if sender.index == 1 {
            
            sortEvents(sortBy: "popular")
            
        } else if sender.index == 2 {
            
            sortEvents(sortBy: "friends")
        }
    }
    /**
     *  Sorts the events array.
     *
     *  - Parameter sortBy: Indicates how the array should be sorted.
     */
    func sortEvents(sortBy: String) {
        
        if sortBy == "popular" {
            
            inFriendMode = false
            events = events.sorted(by: { $0.count > $1.count }) // Sorts the array by the number of people going to the event.
            
        } else if sortBy == "upcoming" {
            
            inFriendMode = false
            events = events.sorted(by: { $0.timeStart.compare($1.timeStart) == ComparisonResult.orderedAscending }) // Sorts the array by how close the event is time-wise.
            
        } else if sortBy == "friends" {
            
            inFriendMode = true
        }
        
        self.eventsView.reloadData() // Reloads the events.
    }
        
    // MARK: - TRANSITION
    
    /**
     *  Segues to the add event screen.
     *
     */
    func goToAddEventScreen() {
        
        self.performSegue(withIdentifier: "showAddEvent", sender: self)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showDetails" {
            
            let destinationController: DetailController = segue.destination as! DetailController
            
            if let indexPath = self.eventsView.indexPathForSelectedRow {
                
                destinationController.event = events[indexPath.row] // Passes the event to the detail screen.
            }
        }
    }
}

extension BoardController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == "" {
            
            inSearchMode = false // This means the user is NOT typing in the searchBar.
            
            eventsView.reloadData()
            
        } else {
            
            inSearchMode = true // This means the user is typing in the searchBar.
            
            filteredEvents = events.filter({$0.title.range(of: searchBar.text!) != nil}) // Filters the list of events as the user types into a new array.
            
            eventsView.reloadData() // Reloads the events view as the filtering occurs.
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        /* This function is called when the user clicks the return key while editing of the searchBar is enabled. */
        
        searchBar.resignFirstResponder() // Dismisses the keyboard for the search bar.
    }
}

extension BoardController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1 // We only need a single section for now.
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.performSegue(withIdentifier: "showDetails", sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 140.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if inSearchMode == true {
            
            return filteredEvents.count
            
        } else if inFriendMode == true {
            
            return friendEvents.count
        }
        
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var event = events[indexPath.row]
        
        if inSearchMode == true {
            
            event = filteredEvents[indexPath.row]
            
        } else if inFriendMode == true {
            
            event = friendEvents[indexPath.row]
        }
        
        if let cell = eventsView.dequeueReusableCell(withIdentifier: "event") as? EventCell {
            
            if let img = BoardController.imageCache.object(forKey: event.imageURL as NSString) {
                
                cell.configureCell(event: event, img: img)
                return cell
                
            } else {
                
                cell.configureCell(event: event)
                return cell
            }
        } else {
            
            return EventCell()
        }
    }
}
