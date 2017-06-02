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
import Lottie

class BoardController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var sortControlView: View!
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var eventsView: UITableView!
    
    // MARK: - VARIABLES
    
    let navigationBarTitle = UILabel()
    var navigationBarAddButton = UIBarButtonItem()
    var navigationBarProfileButton = UIBarButtonItem()
    
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
    
    /// Holds all the friend keys under the current user.
    var userFriendKeys = [String]()
    
    /// Tells when user is typing in the searchBar.
    var inSearchMode = false
    
    var event = Event(board: String(), count: Int(), creator: String(), description: String(), imageURL: String(), location: String(), publicMode: Bool(), timeStart: String(), timeEnd: String(), title: String(), coordinate: CLLocationCoordinate2D())
    
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
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
        
        /* Add Event button */
        navigationBarAddButton = UIBarButtonItem(image: UIImage(named: "ic-add-event"), style: .plain, target: self, action: #selector(BoardController.goToAddEventScreen))
        navigationBarAddButton.tintColor = UIColor.white
        self.parent?.navigationItem.leftBarButtonItem  = navigationBarAddButton
        
        /* Profile button */
        navigationBarProfileButton = UIBarButtonItem(image: UIImage(named: "ic-user"), style: .plain, target: self, action: #selector(BoardController.goToProfileScreen))
        navigationBarProfileButton.tintColor = UIColor.white
        self.parent?.navigationItem.rightBarButtonItem  = navigationBarProfileButton
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
        
        grabUserFriends()
        checkEventRequests()
    }
    
    func loadIndicator() {
        
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = .white
        self.view.addSubview(activityIndicator)
        self.eventsView.isHidden = true
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func stopIndicator() {
        
        activityIndicator.stopAnimating()
        self.eventsView.isHidden = false
        UIApplication.shared.endIgnoringInteractionEvents()
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
    
    func checkEventRequests() {
        
        DataService.ds.REF_CURRENT_USER_EVENTS.observe(.value, with: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    
                    let value = snap.value
                    
                    let check = value! as! Bool
                    
                    if check == false {
                        
                        self.grabInvitedEvent(key: key)
                    }
                }
            }
        })
    }
    
    func presentEventNotice(key: String) {
        
        let notice = SCLAlertView()
        
        notice.addButton("Yes!") {
            
            /* The user has given permission to see the event. */
            
           self.performSegue(withIdentifier: "showDetails", sender: self)
        }
        
        notice.showInfo("Event request!", subTitle: "You've been invited to \(event.title). Would you like to see details?", closeButtonTitle: "No")
        
        let ref = DataService.ds.REF_CURRENT_USER_EVENTS.child(key)
        ref.removeValue()
    }
    
    func grabInvitedEvent(key: String) {
        
        DataService.ds.REF_EVENTS.observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.userFriendKeys = []
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        if snap.key == key {
                        
                            let event = Event(eventKey: key, eventData: eventDict) // Format the data using the Event model.

                            self.event = event
                        }
                    }
                }
            }
            
            self.presentEventNotice(key: key)
        
        }) { (error) in
            
            // Error!
            
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't find ythe event.")
        }
    }
    
    /**
     *  Uses the keys received from under the current board's data reference to find and grab the data relating to the keys.
     */
    func grabEventData() {
       
        let currentDate = Date()
        
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.short
        
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
                            
                                let eventStartTime = formatter.date(from: event.timeStart)
                                
                                if eventStartTime! > currentDate {
                                    
                                    self.events.append(event) // Add the event to the events array.
                                    self.saveEventImageToCache(eventImageURL: event.imageURL)
                                }
                                
                                break // We no longer need to check if the key matches another event.
                            }
                        }
                    }
                }
            }
            
            self.eventsView.reloadData()
            self.stopIndicator()
        })
    }
    
    func saveEventImageToCache(eventImageURL: String) {
        
        let ref = FIRStorage.storage().reference(forURL: eventImageURL)
        
        ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                /* ERROR: Unable to download photo from Firebase storage. */
                
            } else {
                
                /* SUCCESS: Image downloaded from Firebase storage. */
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        print("SAVED")
                        
                        BoardController.imageCache.setObject(img, forKey: eventImageURL as NSString) // Save to image cache.
                    }
                }
            }
        })
    }
    
    /**
     *  Checks what friends belong to the current user.
     */
    func grabUserFriends() {
        
        loadIndicator()
        
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
            titles: ["School", "Popular", "Nearby"],
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
        
        loadIndicator()
        
        if sender.index == 0 {
            
            sortEvents(sortBy: "school")
            
        } else if sender.index == 1 {
            
            sortEvents(sortBy: "popular")
            
        } else if sender.index == 2 {
            
            sortEvents(sortBy: "nearby")
        }
    }
    /**
     *  Sorts the events array.
     *
     *  - Parameter sortBy: Indicates how the array should be sorted.
     */
    func sortEvents(sortBy: String) {
        
        if sortBy == "popular" {
            
            events = events.sorted(by: { $0.count > $1.count }) // Sorts the array by the number of people going to the event.
            
        } else if sortBy == "school" {
            
            events = events.sorted(by: { $0.timeStart.compare($1.timeStart) == ComparisonResult.orderedDescending }) // Sorts the array by how close the event is time-wise.
            
        } else if sortBy == "nearby" {
            
            events = events.sorted(by: { $0.timeStart.compare($1.timeStart) == ComparisonResult.orderedAscending }) // Sorts the array by how close the event is time-wise.
        }
        
        self.eventsView.reloadData() // Reloads the events.
        stopIndicator()
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
     *  Segues to the add event screen.
     *
     */
    func goToProfileScreen() {
        
        self.performSegue(withIdentifier: "showProfile", sender: self)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 280.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if inSearchMode == true {
            
            return filteredEvents.count
            
        }
        
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var event = events[indexPath.row]
        
        if inSearchMode == true {
            
            event = filteredEvents[indexPath.row]
            
        }
        
        if let cell = eventsView.dequeueReusableCell(withIdentifier: "event") as? EventCell {
            
            if let img = BoardController.imageCache.object(forKey: event.imageURL as NSString) {
                
                cell.configureCell(event: event, img: img)
                cell.grabEventFriends(userFriendKeys: self.userFriendKeys)
                return cell
                
            } else {
                
                print("WHAT")
                cell.configureCell(event: event)
                cell.grabEventFriends(userFriendKeys: self.userFriendKeys)
                return cell
            }
            
        } else {
            
            return EventCell()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        /* Set the initial state of the cell. */
        cell.alpha = 0
        //let transform = CATransform3DTranslate(CATransform3DIdentity, -250, 0, 0)
        //cell.layer.transform = transform
        
        /* Animation to change the state of the cell. */
        UIView.animate(withDuration: 0.5) {
            
            //cell.layer.transform = CATransform3DIdentity
            cell.alpha = 1.0
        }
    }
}
