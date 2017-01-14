//
//  FriendCell.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/21/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class FriendCell: UICollectionViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    
    // MARK: - Variables
    
    var friend: User!
    
    override func awakeFromNib() {
        
        friendImageView.clipsToBounds = true
    }
    
    func configureCell(friend: User, img: UIImage? = nil) {
        
        self.friend = friend
        
        self.friendNameLabel.text = friend.name
        
        /* Checks to see if the image is located in the cache. */
        
        if img != nil {
            
            /* If it is, just grab it and set the image view to the cached image. */
            self.friendImageView.image = img
            
        } else {
            
            /* If it isn't, save it the cache. */
            
            let ref = FIRStorage.storage().reference(forURL: friend.image)
            
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    /* ERROR: Unable to download photo from Firebase storage. */
                    
                } else {
                    
                    /* SUCCESS: Image downloaded from Firebase storage. */
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            self.friendImageView.image = img
                            
                            BoardController.imageCache.setObject(img, forKey: friend.image as NSString) // Save to image cache.
                        }
                    }
                }
            })
        }
    }
}
