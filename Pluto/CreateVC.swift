//
//  CreateVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/1/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class CreateVC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var titleField: TextField!
    @IBOutlet weak var timeField: TextField!
    
    // MARK: - Variables
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // MARK: - Button Actions
    
    @IBAction func createButtonAction(_ sender: AnyObject) {
        
        grabBoardKey()
        
        // Switches to the main screen.
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Board")
        self.present(vc!, animated: true, completion: nil)
    }
    
    }
