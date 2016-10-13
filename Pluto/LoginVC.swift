//
//  ViewController.swift
//  Pluto
//
//  Created by Faisal Lalani on 9/11/16.
//  Copyright © 2016 Faisal M. Lalani. All rights reserved.
//

import Firebase
import FirebaseAuth
import pop
import UIKit

class LoginVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UISearchBarDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var goButton: Button!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
        
    @IBOutlet weak var findSchoolAlert: EventView!
    @IBOutlet weak var findSchoolGoButton: Button!
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var searchPreview: UITableView!
    
    // MARK: - Variables
    
    var inSearchMode = false
    
    var boardCount = 0
    var boardExistCount = 0
    
    var boards = [Board]()
    var filteredBoards = [Board]()
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // tabBarController?.tabBar.layer.isHidden = true
        
        // Dismisses the keyboard if the user taps anywhere on the screen.
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginVC.dismissKeyboard)))
        
        // Sets the text field delegates accordingly.
        emailField.delegate = self
        passwordField.delegate = self
        
        // Sets the table view delegate/data source accordingly.
        searchPreview.dataSource = self
        searchPreview.delegate = self
        
        // Sets the search delegates accordingly.
        searchBar.delegate = self
        searchPreview.dataSource = self
        searchPreview.delegate = self
        
        // Changes the font and font size for text inside the search bar.
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont(name: "Open Sans", size: 15)
        textFieldInsideUISearchBar?.textColor = UIColor.black
        let textFieldInsideUISearchBarLabel = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideUISearchBarLabel?.font = UIFont(name: "Open Sans", size: 15)
        textFieldInsideUISearchBarLabel?.textColor = UIColor.black
        
        // Hides empty cells.
        searchPreview.tableFooterView = UIView()
    }
    
    // MARK: - Button Actions
    
    @IBAction func goButtonAction(_ sender: AnyObject) {
        
        dismissKeyboard()
        firebaseLoginSignupVoodoo(email: emailField.text!, password: passwordField.text!)
    }
    
    @IBAction func findSchoolGoButton(_ sender: AnyObject) {
        
        dismissKeyboard()
        
        emailField.text = ""
        passwordField.text = ""
        searchBar.text = ""
        findSchoolAlert.alpha = 0
        
        if searchBar.text != nil {
            
            saveSchoolVoodoo(schoolName: searchBar.text! as String)
            
            // Transitions to the main board screen.
            self.tabBarController?.selectedIndex = 2
        }
    }
    
    // MARK: - Firebase
    
    /**
     
     Saves the user to the database.
     
     */
    func saveToDatabaseVoodoo(user: FIRUser?, userID: String, email: String, providerID: String) {
        
        // Makes sure the user exists first.
        if let user = user {
            
            // Creates a dictionary that will be saved to the database.
            let userData = ["provider": providerID,
                            "email": email]
            
            DataService.ds.createFirebaseDBUser(uid: user.uid, userData: userData)
        }
    }
    
    /**
     
     Logs the user in if successful; creates an account if user is not found in database.
     
     */
    func firebaseLoginSignupVoodoo(email: String, password: String) {
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            
            if error == nil {
                
                // Success! The user has logged in!
                
                self.saveUser(user: user!, userID: (user?.uid)!, email: email, password: password, providerID: (user?.providerID)!)
                
                // Transitions to the main board screen.
                self.tabBarController?.selectedIndex = 2
                
            } else {
                
                // Error!
                
                if error?._code == STATUS_ACCOUNT_NONEXIST {
                    
                    FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                        
                        if error != nil {
                            
                            // Error!
                            
                            SCLAlertView().showError("Oh no!", subTitle: "Pluto could not create an account for you at this time.")
                            
                        } else {
                            
                            // Success! The user has been created!
                            
                            self.saveUser(user: user!, userID: (user?.uid)!, email: email, password: password, providerID: (user?.providerID)!)
                            
                            self.callFindSchoolAlert()
                        }
                    })
                } else {
                    
                    SCLAlertView().showError("Oh no!", subTitle: "Pluto could not log you in at this time.")
                }
            }
        })
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
                            
                            self.saveBoardDefault(board: board.boardKey)
                            
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
    
    func animateFade(view: UIView, alpha: CGFloat) {
        
        UIView.animate(withDuration: 0.3) {
            
            view.alpha = alpha
        }
    }
    
    func dismissKeyboard() {
        
        // Dismisses the keyboard for these text fields.
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    func callFindSchoolAlert() {
        
        parseSchoolsCSV()
        
        // Brings up the alert.
        animateFade(view: findSchoolAlert, alpha: 1.0)
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
    
    /**
     
     Saves the user's email and password to NSUserDefaults to bypass login for future use.
     
     */
    func saveDefault(email: String, password: String) {
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(email, forKey: "email")
        userDefaults.set(password, forKey: "password")
    }
    
    func saveBoardDefault(board: String) {
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(board, forKey: "board")
    }
    
    func saveUser(user: FIRUser?, userID: String?, email: String, password: String, providerID: String) {
        
        saveToDatabaseVoodoo(user: user, userID: userID!, email: email, providerID: providerID)
        saveDefault(email: email, password: password)
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
        animateFade(view: findSchoolGoButton, alpha: 1.0)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        animateFade(view: findSchoolGoButton, alpha: 0)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        animateFade(view: findSchoolGoButton, alpha: 1.0)
    }
    
    // MARK: - Text Field Functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard.
        textField.resignFirstResponder()
        return true
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
        cell.textLabel?.textColor = UIColor.black
        cell.textLabel?.font = UIFont(name: "Open Sans", size: 13)
        
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
