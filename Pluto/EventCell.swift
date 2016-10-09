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
    
    // MARK: - Variables
    var event: Event!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(event: Event) {
        
        self.event = event
        self.eventTitleLabel.text = event.title
    }
}
