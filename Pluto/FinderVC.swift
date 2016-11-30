//
//  FinderVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 11/26/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class FinderVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var searchPreview: UITableView!
    
    // MARK: - Variables
    
    /// Counts the number of events in the Firebase database.
    var eventCount = 0
    /// This counts the boards along with eventCount **IF** the event title doesn't equal to what's in the searchBar.
    var eventExistCount = 0
    
    /// Holds all the board titles from the CSV file.
    var events = [Board]()
    /// Holds all the filtered board titles as the filtering function does its work.
    var filteredEvents = [Board]()
    
    /// Tells when user is typing in the searchBar.
    var inSearchMode = false
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the search preview
        searchPreview.dataSource = self
        searchPreview.delegate = self
        
        // Hides the empty cells in the searchPreview.
        searchPreview.tableFooterView = UIView()
        
        // Initializes the searchBar.
        searchBar.delegate = self
        
        // Automatically calls keyboard.
        searchBar.becomeFirstResponder()
        
        // Changes the font and font size for text inside the searchBar.
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont(name: "Lato", size: 15)
        textFieldInsideUISearchBar?.textColor = UIColor.white
        
        // This does the same thing as above but this is for the placeholder text.
        let textFieldInsideUISearchBarLabel = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideUISearchBarLabel?.font = UIFont(name: "Lato", size: 15)
        textFieldInsideUISearchBarLabel?.textColor = UIColor.white
        textFieldInsideUISearchBarLabel?.text = "Search for your school"
        
//        parseSchoolsCSV()
    }
    
    // MARK: - Helpers
    
    /**
     Clears the search bar so if the user returns, it'll be blank.
     */
    
    func clearFields() {
        
        searchBar.text = ""
    }
    
    /**
     Dismisses the keyboard!
     
     Just put whatever textfields you want included here in the function.
     */
    func dismissKeyboard() {
        
        // Dismisses the keyboard for the search bar.
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Search Bar Functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        // This function is called as the user types in the searhBar.
        
        if searchBar.text == "" {
            
            // This means the user is NOT typing in the searchBar.
            inSearchMode = false
            
            // Hides the search result previews.
            searchPreview.alpha = 0
            
        } else {
            
            // This means the user is typing in the searchBar.
            inSearchMode = true
            
            // Brings up the search result previews.
            searchPreview.alpha = 1.0
            
            // Filters the list of schools as the user types into a new array.
            filteredEvents = events.filter({$0.title.range(of: searchBar.text!) != nil})
            
            // Reloads the searchPreview as the filtering occurs.
            searchPreview.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // This function is called when the user clicks the return key while editing of the searchBar is enabled.
        
        dismissKeyboard()
        
        // Checks to see if the user inputted anything in the searchBar.
        if searchBar.text != "" {
            
//            saveSchoolVoodoo(schoolName: searchBar.text! as String)
            
            // Transitions to the main board screen.
            self.performSegue(withIdentifier: "showMain", sender: self)
        }
        
        // Returns the bar back to blank so any return to the screen won't have the current user's information.
        self.clearFields()
    }
    
    
    // MARK: - Table View Functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        // We only need 1 section.
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResult", for: indexPath) as UITableViewCell
        
        // Makes the text of each search preview result match what the filter churns out.
        cell.textLabel?.text = filteredEvents[indexPath.row].title
        
        // Changes the text color and font to the app style.
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont(name: "Lato", size: 16)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Changes the search bar text to match the selection the user made.
        searchBar.text = filteredEvents[indexPath.row].title
        
        // Hides the search suggestions.
        searchPreview.alpha = 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Returns only the number of suggestions the filter has for the user's query.
        return filteredEvents.count
    }
}
