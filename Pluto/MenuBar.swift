//
//  MenuBar.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/10/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import GooglePlaces

protocol ZoomToCurrentLocDelegate {
    
    func centerOnUserLoc()
    func centerOnSearchedLoc(loc: CLLocationCoordinate2D)
}

class MenuBar: UIView {
    
    // MARK: - Outlets
    
    @IBOutlet weak var searchLocButton: UIButton!
    @IBOutlet weak var userLocButton: UIButton!
    
    // MARK: - Variables
    
    var zoomDelegate: ZoomToCurrentLocDelegate?
    
    override func layoutSubviews() {
        
        self.layer.cornerRadius = 20
        
        searchLocButton.translatesAutoresizingMaskIntoConstraints = false
        addSearchButtonConstraints()
        userLocButton.translatesAutoresizingMaskIntoConstraints = false
        addUserLocButtonConstraints()
    }
    
    // MARK: - Button Actions
    
    @IBAction func searchLocButtonAction(_ sender: Any) {
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        let superView = self.superview?.next as! MainController
        superView.present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func userLocButtonAction(_ sender: Any) {
        
        zoomDelegate?.centerOnUserLoc()
    }
}

extension MenuBar: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        zoomDelegate?.centerOnSearchedLoc(loc: place.coordinate)
        
        let superView = self.superview?.next as! MainController
        superView.dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        
        let superView = self.superview?.next as! MainController
        superView.dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension MenuBar {
    
    func addSearchButtonConstraints() {
        
        let widthConstraint = NSLayoutConstraint(
            item: searchLocButton,
            attribute: NSLayoutAttribute.width,
            relatedBy: NSLayoutRelation.equal,
            toItem: nil,
            attribute: NSLayoutAttribute.notAnAttribute,
            multiplier: 1.0,
            constant: self.frame.width / 2
        )
        
        searchLocButton.addConstraint(widthConstraint)
        
        let topConstraint = NSLayoutConstraint(
            item: searchLocButton,
            attribute: NSLayoutAttribute.top,
            relatedBy: NSLayoutRelation.equal,
            toItem: self,
            attribute: NSLayoutAttribute.top,
            multiplier: 1.0,
            constant: 0
        )
        
        self.addConstraint(topConstraint)
        
        let leftConstraint = NSLayoutConstraint(
            item: searchLocButton,
            attribute: NSLayoutAttribute.leading,
            relatedBy: NSLayoutRelation.equal,
            toItem: self,
            attribute: NSLayoutAttribute.leading,
            multiplier: 1.0,
            constant: 0
        )
        
        self.addConstraint(leftConstraint)
        
        let bottomConstraint = NSLayoutConstraint(
            item: searchLocButton,
            attribute: NSLayoutAttribute.bottom,
            relatedBy: NSLayoutRelation.equal,
            toItem: self,
            attribute: NSLayoutAttribute.bottom,
            multiplier: 1.0,
            constant: 0
        )
        
        self.addConstraint(bottomConstraint)
    }
    
    func addUserLocButtonConstraints() {
        
        let widthConstraint = NSLayoutConstraint(
            item: userLocButton,
            attribute: NSLayoutAttribute.width,
            relatedBy: NSLayoutRelation.equal,
            toItem: nil,
            attribute: NSLayoutAttribute.notAnAttribute,
            multiplier: 1.0,
            constant: self.frame.width / 2
        )
        
        userLocButton.addConstraint(widthConstraint)
        
        let topConstraint = NSLayoutConstraint(
            item: userLocButton,
            attribute: NSLayoutAttribute.top,
            relatedBy: NSLayoutRelation.equal,
            toItem: self,
            attribute: NSLayoutAttribute.top,
            multiplier: 1.0,
            constant: 0
        )
        
        self.addConstraint(topConstraint)
        
        let rightConstraint = NSLayoutConstraint(
            item: userLocButton,
            attribute: NSLayoutAttribute.trailing,
            relatedBy: NSLayoutRelation.equal,
            toItem: self,
            attribute: NSLayoutAttribute.trailing,
            multiplier: 1.0,
            constant: 0
        )
        
        self.addConstraint(rightConstraint)
        
        let bottomConstraint = NSLayoutConstraint(
            item: userLocButton,
            attribute: NSLayoutAttribute.bottom,
            relatedBy: NSLayoutRelation.equal,
            toItem: self,
            attribute: NSLayoutAttribute.bottom,
            multiplier: 1.0,
            constant: 0
        )
        
        self.addConstraint(bottomConstraint)
    }
}
