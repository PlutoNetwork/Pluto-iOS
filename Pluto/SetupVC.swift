//
//  SetupVC.swift
//  Pluto
//
//  Created by Faisal Lalani on 9/12/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import UIKit

class SetupVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: - Outlets
    
    // Buttons
    @IBOutlet weak var goButton: Button!
    
    // Labels
    @IBOutlet weak var questionLabel: UILabel!
    
    // Search
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchPreview: UITableView!

    // MARK: - Variables
    
    var inSearchMode = false
    
    var boardCount = 0
    var boardExistCount = 0
    
    var boards = [Board]()
    var filteredBoards = [Board]()
    
    // MARK: - View Functions
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Checks if user has a board saved already.
        checkIfBoardSaved()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets the search delegates accordingly.
        searchBar.delegate = self
        searchPreview.dataSource = self
        searchPreview.delegate = self
        
        // Changes the font and font size for text inside the search bar.
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont(name: "Open Sans", size: 15)
        let textFieldInsideUISearchBarLabel = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideUISearchBarLabel?.font = UIFont(name: "Open Sans", size: 15)
        
        // Hides empty cells.
        searchPreview.tableFooterView = UIView()
        
        parseSchoolsCSV()
    }
    
    // MARK: - Button Actions
    
    @IBAction func goButtonAction(_ sender: AnyObject) {
        
        dismissKeyboard()
        
        if searchBar.text != nil {
            
            saveSchoolVoodoo(schoolName: searchBar.text! as String)

            // Switches to the board screen.
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "Board")
            self.present(vc!, animated: true, completion: nil)
        }
    }
    
    // MARK: - Firebase
    
    func checkIfBoardSaved() {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        DataService.ds.REF_USERS.child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            
            let value = snapshot.value as? NSDictionary
            
            if value?["board"] != nil {
                
                // Switches to the board screen.
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "Main")
                self.present(vc!, animated: true, completion: nil)
                
            }
            
        }) { (error) in
            
            // Error!
            
            print(error.localizedDescription)
        }
    }
    
    func createBoard(schoolName: String) {
        
        let board: Dictionary<String, AnyObject> = [
        
            "title": schoolName as AnyObject
        
        ]
        
        let newBoard = DataService.ds.REF_BOARDS.childByAutoId()
        newBoard.setValue(board)
    }
    
    /**
 
     Saves the user's school to his/her account on Firebase.
 
    */
    func saveSchoolVoodoo(schoolName: String) {
        
        DataService.ds.REF_BOARDS.observe(.value, with: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
            
                for snap in snapshot {
                    
                    if let boardDict = snap.value as? Dictionary<String, AnyObject> {
                     
                        let key = snap.key
                        let board = Board(boardKey: key, boardData: boardDict)
                        
                        self.boardCount += 1
                        
                        if board.title != schoolName {
                            
                            self.boardExistCount += 1
                            
                        } else {
                            
                            let user = FIRAuth.auth()?.currentUser
                            
                            let childUpdates = ["board": board.boardKey]
                            
                            DataService.ds.REF_USERS.child("\((user?.uid)!)").updateChildValues(childUpdates)
                            
                            self.saveDefault(board: board.boardKey)
                            
                        }
                    }
                }
            }
            
            // If board doesn't already exist, create a new one.
            if self.boardExistCount == self.boardCount {
                
                self.createBoard(schoolName: schoolName)
                
            }
        })
    }
    
    // MARK: - Helpers

    func dismissKeyboard() {
        
        // Dismisses the keyboard.
        searchBar.resignFirstResponder()
    }
    
    func saveDefault(board: String) {
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(board, forKey: "board")
    }
    
    /**
     
     Reads the schools.csv file to compile list of all schools in the nation.
 
    */
    func parseSchoolsCSV() {
        
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
            
            print(error.debugDescription)
        }
    }
    
    // MARK: - Search Bar Functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == nil || searchBar.text == "" {
            
            // This means the user is NOT typing in the search bar.
            inSearchMode = false
            
            // Hides the search result previews.
            searchPreview.alpha = 0
            
        } else {
            
            // This means the user is typing in the search bar.
            inSearchMode = true
            
            // Brings up the search result previews.
            searchPreview.alpha = 1.0
            
            // Filters the list of schools as the user types into a new array.
            filteredBoards = boards.filter({$0.title.range(of: searchBar.text!) != nil})
            searchPreview.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
       
        dismissKeyboard()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        AnimationEngine.animateToPosition(view: self.goButton, position: CGPoint(x: AnimationEngine.centerPosition.x, y: AnimationEngine.offScreenBottomPosition.y + 1000))
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        AnimationEngine.animateToPosition(view: self.goButton, position: CGPoint(x: AnimationEngine.centerPosition.x, y: AnimationEngine.centerPosition.y))
    }
    
    // MARK: - Table View Functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        // Returns only 1 column.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Returns only the number of suggestions the filter has for the user's query.
        return filteredBoards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResult", for: indexPath) as UITableViewCell
        
        // Makes the text of each search preview result match what the filter churns out.
        cell.textLabel?.text = filteredBoards[indexPath.row].title
        
        // Changes the text color and font to the app style.
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont(name: "Open Sans", size: 15)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Changes the search bar text to match the selection the user made.
        searchBar.text = filteredBoards[indexPath.row].title
        
        // Hides the search suggestions.
        searchPreview.alpha = 0
        
        dismissKeyboard()
    }
}
