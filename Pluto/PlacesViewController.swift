//
//  PlacesViewController.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/2/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import GooglePlaces

class PlacesViewController: UIViewController {
    
    // MARK: - Variables
    
    // An array to hold the list of possible locations.
    var likelyPlaces: [GMSPlace] = []
    var selectedPlace: GMSPlace?
    
    // Cell reuse id (cells that scroll out of view can be reused).
    let cellReuseIdentifier = "cell"
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "unwindToMain" {
            
            if let nextViewController = segue.destination as? MainViewController {
                
                nextViewController.selectedPlace = selectedPlace
            }
        }
    }
}

extension PlacesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedPlace = likelyPlaces[indexPath.row]
        performSegue(withIdentifier: "unwindToMain", sender: self)
    }
}

extension PlacesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return likelyPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        let collectionItem = likelyPlaces[indexPath.row]
        
        cell.textLabel?.text = collectionItem.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        /* Show only the first five items in the table (scrolling is disabled in IB). */
        
        return self.tableView.frame.size.height/5
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        /* Make table rows display at proper height if there are less than 5 items. */
        
        if (section == tableView.numberOfSections - 1) {
            
            return 1
        }
        
        return 0
    }
}
