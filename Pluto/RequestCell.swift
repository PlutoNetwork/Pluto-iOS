//
//  RequestCell.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/21/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class RequestCell: UICollectionViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var friendImage: UIImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    
    
    // MARK: - Variables
    
    var friend: Friend!
    
    func configureCell(friend: Friend) {
        
        self.friend = friend
        
        DataService.ds.REF_USERS.child(friend.friendKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            
            if value?["image"] != nil {
                
                // Downloads the set profile image.
                self.downloadProfileImage(imageURL: (value?["image"] as? String)!)
            }
            
            if value?["name"] != nil {
                
                self.friendNameLabel.text = value?["name"] as? String
                
            } else {
                
                self.friendNameLabel.text = value?["email"] as? String
            }
        })
    }
    
    func downloadProfileImage(imageURL: String) {
        
        let ref = FIRStorage.storage().reference(forURL: imageURL)
        ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                // Error! Unable to download photo from Firebase storage.
                
            } else {
                
                // Image successfully downloaded from Firebase storage.
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        self.friendImage.image = img
                        
                        // Save to image cache (globally declared in BoardVC)
                        BoardVC.imageCache.setObject(img, forKey: imageURL as NSString)
                    }
                }
            }
        })
    }
    
    // MARK: - Button Actions
    
    @IBAction func thumbsUpButton(_ sender: AnyObject) {
        
        print("UP")
    }
    
    @IBAction func thumbsDownButton(_ sender: AnyObject) {
        
        print("DOWN")
    }
}
