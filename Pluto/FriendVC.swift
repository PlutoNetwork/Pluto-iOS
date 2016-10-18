//
//  FriendVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/16/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class FriendVC: UIViewController, FriendsDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var userProfileImageView: RoundImageView!
    @IBOutlet weak var eventView: UITableView!
    
    // MARK: - Variables

    var creatorID = String()
    
    /// Holds all the event data received from Firebase.
    var events = [Event]()
    
    var creatorEventKeys = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUserInfo()
        grabUserEvents()
    }
    
    // MARK: - Button Actions
    
    @IBAction func backButtonAction(_ sender: AnyObject) {
        
        switchController(controllerID: "Main")
    }
    
    // MARK: - Firebase
    
    /**
     Goes into Firebase storage to download the user's set profile image.
     
     - Parameter imageURL: A string that holds a reference to where the image is stored in the Firebase storage.
     */
    func downloadProfileImage(imageURL: String) {
        
        /// Uses the parameter (imageURL) to make a complete link to where the image is stored in the Firebase storage.
        let ref = FIRStorage.storage().reference(forURL: imageURL)
        
        // withMaxSize was computed in a tutorial online that found it to be ideal for the limit.
        ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                // Error! Unable to download photo from Firebase storage.
                SCLAlertView().showError("Oh no!", subTitle: "Pluto was unable to find your profile photo.")
                
                // Instead, set the profile image view to the profile placeholder image.
                self.userProfileImageView.image = UIImage(named: "profile_img_placeholder")
                
            } else {
                
                // Success! Image successfully downloaded from Firebase storage.
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        // Set the profile image view to the downloaded image.
                        self.userProfileImageView.image = img
                        
                        // Save to image cache (globally declared in BoardVC).
                        BoardVC.imageCache.setObject(img, forKey: imageURL as NSString)
                    }
                }
            }
        })
    }
    
    func grabUserEvents() {
        
        DataService.ds.REF_USERS.child(creatorID).child("events").observeSingleEvent(of: .value, with: { (snapshot) in
                        
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    self.creatorEventKeys.append(snap.key)
                }
            }
        })
    }
    
    func setUserInfo() {
        
        DataService.ds.REF_USERS.child(creatorID).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            // Checks to see if the user has a set profile image.
            if value?["image"] != nil {
                
                // Downloads the set profile image.
                self.downloadProfileImage(imageURL: (value?["image"] as? String)!)
            }
            
            if value?["name"] != nil {
                
                self.nameLabel.text = (value?["name"] as? String)?.uppercased()
                
            } else {
                
                self.nameLabel.text = (value?["email"] as? String)?.uppercased()
            }
            
            if value?["year"] != nil {
                
                self.yearLabel.text = (value?["year"] as? String)
                
            }
            
            if value?["major"] != nil {
                
                self.majorLabel.text = (value?["major"] as? String)
                
            }
            
        })  { (error) in
            
            // Error!
            
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't find your school.")
        }
    }
    
    // MARK: - Helpers
    
    func switchController(controllerID: String) {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: controllerID) as UIViewController
        self.present(vc, animated: true, completion: nil)
    }
    
    func switchToProfile(creatorID: String) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Friend") as! FriendVC
        
        controller.creatorID = creatorID
        
        self.present(controller, animated: true, completion: nil)
    }
    
    // MARK: - Table View Functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        // We only need a single section for now.
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Didn't use the switchController function because we have to pass data into the next viewController.
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Details") as! DetailsVC
        
        controller.eventKey = events[indexPath.row].eventKey
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 140.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Sort by popularity.
        events = events.sorted(by: { $0.count > $1.count })
        
        let event = events[indexPath.row]
        
        if let cell = eventView.dequeueReusableCell(withIdentifier: "event") as? EventCell {
            
            cell.delegate = self
            
            if let img = BoardVC.imageCache.object(forKey: event.imageURL as NSString) {
                
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
