//
//  CollectionViewCell.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 1/12/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import Firebase

class ImageCell: UICollectionViewCell {
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - VARIABLES
    
    var image: Image!
    
    func configureCell(image: Image, img: UIImage? = nil) {
        
        self.image = image
        
        /* Checks to see if the image is located in the cache. */
        
        if img != nil {
            
            /* If it is, just grab it and set the image view to the cached image. */
            self.imageView.image = img
            
        } else {
            
            /* If it isn't, save it the cache. */
            
            downloadImage(imageURL: image.imageURL)
        }
    }
    
    func downloadImage(imageURL: String) {
        
        let ref = FIRStorage.storage().reference(forURL: imageURL)
        ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                // Error! Unable to download photo from Firebase storage.
                
            } else {
                
                // Image successfully downloaded from Firebase storage.
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        self.imageView.image = img
                        
                        // Save to image cache (globally declared in BoardVC)
                        BoardController.imageCache.setObject(img, forKey: imageURL as NSString)
                    }
                }
            }
        })
    }
}
