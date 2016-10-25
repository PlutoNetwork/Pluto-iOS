//
//  SearchVC.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 10/24/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import UIKit

class SearchVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var searchPreview: UITableView!
    
    // MARK: - Variables
    
    /// Counts the number of boards in the Firebase database.
    var boardCount = 0
    /// This counts the boards along with boardCount **IF** the board title doesn't equal to what's in the searchBar.
    var boardExistCount = 0
    
    /// Holds all the board titles from the CSV file.
    var boards = [Board]()
    /// Holds all the filtered board titles as the filtering function does its work.
    var filteredBoards = [Board]()
    
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
        textFieldInsideUISearchBar?.font = UIFont(name: "Open Sans", size: 15)
        textFieldInsideUISearchBar?.textColor = UIColor.white
        
        // This does the same thing as above but this is for the placeholder text.
        let textFieldInsideUISearchBarLabel = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideUISearchBarLabel?.font = UIFont(name: "Open Sans", size: 15)
        textFieldInsideUISearchBarLabel?.textColor = UIColor.white
        textFieldInsideUISearchBarLabel?.text = "Search for your school"
        
        parseSchoolsCSV()
    }
    
    // MARK: - Firebase
    
    /**
     Called when the specified board could not be found. This means a new board must be created.
     
     - Parameter schoolName: The name of the school, gotten from the text in the searchBar.
     */
    func createBoard(schoolName: String) {
        
        // Creates a dictionary for the board information that will be saved to the database.
        let board: Dictionary<String, AnyObject> = ["title": schoolName as AnyObject]
        
        /// Holds a reference to a new board created by Firebase with a randomly generated ID.
        let newBoardRef = DataService.ds.REF_BOARDS.childByAutoId()
        // Adds the new board under the reference in the Firebase database.
        newBoardRef.setValue(board)
        
        // Calls the function that called it expecting a different result because this time, the board DOES exist.
        saveSchoolVoodoo(schoolName: schoolName)
    }
    
    /**
     Called after the user selects a school.
     
     Saves the user's school to his/her account on Firebase.
     
     - Parameter schoolName: The name of the school, gotten from the text in the searchBar.
     */
    func saveSchoolVoodoo(schoolName: String) {
        
        // Opens a reference to the boards stored on the Firebase database.
        DataService.ds.REF_BOARDS.observe(.value, with: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                // Goes through all the keys under the boards in the database.
                for snap in snapshot {
                    
                    // Looks through the data under each board as a dictionary.
                    if let boardDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        let board = Board(boardKey: key, boardData: boardDict)
                        
                        // Counts all the boards in the database.
                        self.boardCount += 1
                        
                        if board.title != schoolName {
                            // If the board title doesn't match what the user inputted in the searchBar, it adds 1 to this count.
                            self.boardExistCount += 1
                            
                        } else {
                            
                            // A matching board title was found, which means the board already exists in the database.
                            
                            /// Holds a key and value that will be used to update the user's data.
                            let childUpdates = ["board": board.boardKey]
                            
                            // Goes into the current user's data to update their board.
                            DataService.ds.REF_CURRENT_USER.updateChildValues(childUpdates)
                            
                            // There's no need to keep counting, so we can exit the for loop.
                            break
                        }
                    }
                }
            }
            
            // If board doesn't already exist, create a new one. This is evidenced by the fact that both these counts are equal. If the board *was* in the database, boardExistCount would be 1 less than boardCount.
            if self.boardExistCount == self.boardCount {
                
                self.createBoard(schoolName: schoolName)
            }
        })
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
    
    /**
     Reads the schools.csv file downloaded from the Dept. of Education and grabs all of the school names to be used in the searchPreview as the user types in the searchBar.
     */
    func parseSchoolsCSV() {
        
        /// Defines the location of where the CSV file is saved.
        let path = Bundle.main.path(forResource: "schools", ofType: "csv")!
        
        do {
            
            let csv = try CSV(contentsOfURL: path)
            let rows = csv.rows
            
            for row in rows {
                
                let title = row["Institution_Name"]
                let school = Board(title: title!)
                boards.append(school)
            }
        } catch let error as NSError {
            
            // Error! The CSV file could not be parsed.
            SCLAlertView().showError("Oh no!", subTitle: "Pluto had an internal error and couldn't get the list of schools for you.")
            
            print("PLUTO INTERNAL ERROR: \(error.debugDescription)")
        }
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
            filteredBoards = boards.filter({$0.title.range(of: searchBar.text!) != nil})
            
            // Reloads the searchPreview as the filtering occurs.
            searchPreview.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // This function is called when the user clicks the return key while editing of the searchBar is enabled.
        
        dismissKeyboard()
        
        // Checks to see if the user inputted anything in the searchBar.
        if searchBar.text != "" {
            
            saveSchoolVoodoo(schoolName: searchBar.text! as String)
            
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
        cell.textLabel?.text = filteredBoards[indexPath.row].title
        
        // Changes the text color and font to the app style.
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont(name: "Open Sans", size: 13)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Changes the search bar text to match the selection the user made.
        searchBar.text = filteredBoards[indexPath.row].title
        
        // Hides the search suggestions.
        searchPreview.alpha = 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Returns only the number of suggestions the filter has for the user's query.
        return filteredBoards.count
    }
}
