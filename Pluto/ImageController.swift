//
//  ImageController.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 1/12/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit

class ImageController: UIViewController {
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - VARIABLES
    
    var image = UIImage()
    
    // MARK: - VIEW
    
    override func viewWillAppear(_ animated: Bool) {
        
        /* Navigation bar customization */
        self.navigationController?.setNavigationBarHidden(true, animated: true) // Keeps the navigation bar hidden.
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let rightGesture = UISwipeGestureRecognizer(target: self, action: #selector(ImageController.swipeRight))
        rightGesture.direction = .right
        imageView.addGestureRecognizer(rightGesture)
        
        imageView.image = image
    }
    
    func swipeRight(sender:UISwipeGestureRecognizer) {
        
        self.navigationController?.popViewController(animated: true)
    }

}
