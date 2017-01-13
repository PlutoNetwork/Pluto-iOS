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

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = image
    }

}
