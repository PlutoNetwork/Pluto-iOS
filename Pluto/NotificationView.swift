//
//  NotificationView.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/11/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit

class NotificationView: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var timer: Timer!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 10.0
        self.layer.masksToBounds = true
        self.layer.borderWidth = 3.0
        self.layer.borderColor = UIColor.white.cgColor
    }
    
    override func awakeFromNib() {
        
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(NotificationView.removeNotification), userInfo: nil, repeats: true)
    }
    
    func removeNotification() {
        
        let superView = self.superview?.next as! MainController
        
        AnimationEngine.animateToPosition(view: self, position: CGPoint(x: AnimationEngine.offScreenRightPosition.x, y: superView.userButton.center.y))
        self.removeFromSuperview()
    }
}
