//
//  BoardVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import UIKit

class BoardController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var eventsView: UITableView!
    
    @IBOutlet weak var popularButton: UIButton!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var friendsButton: UIButton!
    
    // MARK: - VARIABLES
    
    let navigationBarTitle = UILabel()
    var navigationBarAddButton = UIBarButtonItem()
    var navigationBarSearchButton = UIBarButtonItem()
    
    /// Holds all event and profile pictures.
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    /// Holds all the event keys under the current board.
    var boardEventKeys = [String]()
    
    /// Holds the data for all the events under the current board.
    var events = [Event]()
    
    // MARK: - VIEW
    
    override func viewWillAppear(_ animated: Bool) {
        
        /* Navigation bar customization. */
        self.navigationController?.setNavigationBarHidden(false, animated: true) // Presents the navigation bar.
        
        /* Logo in the middle of the navigation bar */
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.contentMode = .scaleAspectFit
        let image = UIImage(named: "logo")
        imageView.image = image
        self.parent?.navigationItem.titleView = imageView
        
        /* Search button */
        navigationBarSearchButton = UIBarButtonItem(image: UIImage(named: "ic-search"), style: .plain, target: self, action: #selector(BoardController.goToAddEventScreen))
        navigationBarSearchButton.tintColor = UIColor.white
        self.parent?.navigationItem.leftBarButtonItem  = navigationBarSearchButton
        
        /* Add event button */
        navigationBarAddButton = UIBarButtonItem(image: UIImage(named: "ic-add-event"), style: .plain, target: self, action: #selector(BoardController.goToAddEventScreen))
        navigationBarAddButton.tintColor = UIColor.white
        self.parent?.navigationItem.rightBarButtonItem  = navigationBarAddButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Initialization of the table view that holds all the events. */
        eventsView.delegate = self
        eventsView.dataSource = self
        
        grabBoardEvents()
    }
    
    // MARK: - BUTTON
    
    @IBAction func popularButtonAction(_ sender: Any) {
        
        popularButton.backgroundColor = YELLOW_COLOR
        popularButton.setTitleColor(VIEW_BACKGROUND_COLOR, for: .normal)
        
        newButton.backgroundColor = VIEW_BACKGROUND_COLOR
        newButton.setTitleColor(YELLOW_COLOR, for: .normal)
        
        friendsButton.backgroundColor = VIEW_BACKGROUND_COLOR
        friendsButton.setTitleColor(YELLOW_COLOR, for: .normal)
        
        self.events = self.events.sorted(by: { $0.count > $1.count })
        self.eventsView.reloadData()
    }
    
    @IBAction func newButton(_ sender: Any) {
        
        popularButton.backgroundColor = VIEW_BACKGROUND_COLOR
        popularButton.setTitleColor(YELLOW_COLOR, for: .normal)
        
        newButton.backgroundColor = YELLOW_COLOR
        newButton.setTitleColor(VIEW_BACKGROUND_COLOR, for: .normal)
        
        friendsButton.backgroundColor = VIEW_BACKGROUND_COLOR
        friendsButton.setTitleColor(YELLOW_COLOR, for: .normal)
        
        events = self.events.sorted(by: { $0.time.compare($1.time) == ComparisonResult.orderedAscending })
        self.eventsView.reloadData()
    }
    
    @IBAction func friendsButtonAction(_ sender: Any) {
        
        popularButton.backgroundColor = VIEW_BACKGROUND_COLOR
        popularButton.setTitleColor(YELLOW_COLOR, for: .normal)
        
        newButton.backgroundColor = VIEW_BACKGROUND_COLOR
        newButton.setTitleColor(YELLOW_COLOR, for: .normal)
        
        friendsButton.backgroundColor = YELLOW_COLOR
        friendsButton.setTitleColor(VIEW_BACKGROUND_COLOR, for: .normal)
        
        self.events = self.events.sorted(by: { $0.count > $1.count })
        self.eventsView.reloadData()
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
                                
                                self.events.append(event) // Add the event to the events array.
                                
                                break // We no longer need to check if the key matches another event.
                            }
                        }
                    }
                }
            }
            
            self.events = self.events.sorted(by: { $0.count > $1.count })
            self.eventsView.reloadData()
        })
    }
        
    // MARK: - HELPERS
    
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
        
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let event = events[indexPath.row]
        
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
