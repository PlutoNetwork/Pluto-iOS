//
//  DetailsVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/16/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class DetailsVC: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var eventImageView: RoundImageView!
    @IBOutlet weak var eventTitleField: UITextField!
    @IBOutlet weak var eventLocationField: UITextField!
    @IBOutlet weak var eventTimeField: UITextField!
    @IBOutlet weak var eventDescriptionField: UITextView!
    
    // MARK: - Variables
    
    var eventKey = String()
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        grabCurrentBoardID()
    }
    
    // MARK: - Button Actions
    
    @IBAction func backButtonAction(_ sender: AnyObject) {
        
        switchController(controllerID: "Main")
    }
    
    // MARK: - Firebase
    
    func downloadEventImage(imageURL: String) {
        
        let ref = FIRStorage.storage().reference(forURL: imageURL)
        ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                // Error! Unable to download photo from Firebase storage.
                
            } else {
                
                // Image successfully downloaded from Firebase storage.
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        self.eventImageView.image = img
                        
                        // Save to image cache (globally declared in BoardVC)
                        BoardVC.imageCache.setObject(img, forKey: imageURL as NSString)
                    }
                }
            }
        })
    }

    
    func grabCurrentBoardID() {
        
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            let currentBoardID = value?["board"] as? String
            self.setEventDetails(currentBoardID: currentBoardID!)
        })
    }
    
    func setEventDetails(currentBoardID: String) {
        
        DataService.ds.REF_BOARDS.child(currentBoardID).child("events").child(eventKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            self.downloadEventImage(imageURL: (value?["imageURL"] as? String)!)
            
            self.eventTitleField.text = value?["title"] as? String
            self.eventLocationField.text = value?["location"] as? String
            self.eventTimeField.text = value?["time"] as? String
            self.eventDescriptionField.text = value?["description"] as? String
        })
    }
    
    // MARK: - Helpers
    
    func switchController(controllerID: String) {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: controllerID) as UIViewController
        self.present(vc, animated: true, completion: nil)
    }
}
