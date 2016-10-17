//
//  SplashVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/17/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import UIKit
//import SplashScreenUI

class SplashVC: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var loadingMessageLabel: UILabel!
    
    // MARK: - Variables
    
    let loadingMessages = ["At least you're not on hold...", "We're testing your patience...", "Testing data on John. We're gonna need another John...", "Time is an illusion...", "Counting backwards from infinity...", "Shovelling coal into the server...", "Swapping time and space...", "Doing the impossible..."]
    
    var splashVC: UIViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var randomIndex = Int(arc4random_uniform(UInt32(self.loadingMessages.count)))
        var delayTime = 2.0
        self.loadingMessageLabel.text = self.loadingMessages[randomIndex]
        
        for _ in 0...5 {
            
            delay(delayTime, closure: {
                
                randomIndex = Int(arc4random_uniform(UInt32(self.loadingMessages.count)))
                self.loadingMessageLabel.text = self.loadingMessages[randomIndex]
            })
            
            delayTime = delayTime + 2
        }
        
        showSplashViewController()
    }
    
    func showSplashViewControllerNoPing() {
        
        if splashVC is SplashViewController {
            
            return
        }
        
        splashVC?.willMove(toParentViewController: nil)
        splashVC?.removeFromParentViewController()
        splashVC?.view.removeFromSuperview()
        splashVC?.didMove(toParentViewController: nil)
        
        let splashViewController = SplashViewController()
        splashVC = splashViewController
        splashViewController.pulsing = true
        
        splashViewController.willMove(toParentViewController: self)
        addChildViewController(splashViewController)
        view.addSubview(splashViewController.view)
        splashViewController.didMove(toParentViewController: self)
    }
    
    func showSplashViewController() {
        
        showSplashViewControllerNoPing()
        
        showMain()
        
        delay(8.00) {
            
            self.showMain()
        }
    }
    
    func showMain() {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: "Main") as UIViewController
        self.present(vc, animated: true, completion: nil)
    }
}

