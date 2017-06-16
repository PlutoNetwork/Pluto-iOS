//
//  ResultCell.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/9/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import Firebase

class ResultCell: UITableViewCell {
    
    var event: Event!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundColor = UIColor.black
        self.textLabel?.textColor = UIColor.lightGray
        self.textLabel?.backgroundColor = UIColor.clear
        
        self.imageView?.layer.masksToBounds = true
        self.imageView?.layer.frame.size = CGSize(width: 50, height: 50)
        self.imageView?.layer.cornerRadius = (self.imageView?.frame.height)! / 2
        
        self.textLabel?.frame = CGRect(x: (self.imageView?.frame.width)! + 50, y: 0, width: (self.textLabel?.frame.width)!, height: (self.textLabel?.frame.height)!)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(event: Event) {
        
        self.event = event
        self.textLabel?.text = event.title
        let eventImageURL = event.imageURL
        
        if let img = MainController.imageCache.object(forKey: eventImageURL as NSString) {
            
            self.imageView?.image = img
            
        } else {
            
            let ref = Storage.storage().reference(forURL: eventImageURL)
            
            ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    /* ERROR: Unable to download photo from Firebase storage. */
                    
                } else {
                    
                    /* SUCCESS: Image downloaded from Firebase storage. */
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            MainController.imageCache.setObject(img, forKey: eventImageURL as NSString) // Save to image cache.
                            
                            self.imageView?.image = img
                        }
                    }
                }
            })
        }
    }
}
