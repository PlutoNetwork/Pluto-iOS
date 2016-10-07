//
//  EventCell.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 9/25/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit

class EventCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var rocketIndicator: UIImageView!
    
    // MARK: - Variables
    var event: Event!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(event: Event) {
        
        self.event = event
        self.eventTitleLabel.text = event.title
        self.timeLabel.text = event.time
    
        if event.rocket == true {
            
            rocketIndicator.image = UIImage(named: "star")
            
        } else {
            
            rocketIndicator.image = UIImage(named: "unstar")
        }
        
    }
}
