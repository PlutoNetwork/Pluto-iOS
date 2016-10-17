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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var goButton: Button!
        
    @IBOutlet weak var findSchoolAlert: EventView!
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var searchPreview: UITableView!
    @IBOutlet weak var findSchoolGoButton: Button!
    
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
        
        tabBarController?.tabBar.isHidden = true
        
        // Initializes the text fields.
        emailField.delegate = self
        passwordField.delegate = self
        
        // Initializes the searchPreview.
        searchPreview.dataSource = self
        searchPreview.delegate = self
        
        // Hides the empty cells in the searchPreview.
        searchPreview.tableFooterView = UIView()
        
        // Initializes the searchBar.
        searchBar.delegate = self
        
        // Changes the font and font size for text inside the search bar.
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont(name: "Open Sans", size: 15)
        textFieldInsideUISearchBar?.textColor = UIColor.black
        
        // This does the same thing as above but this is for the placeholder text.
        let textFieldInsideUISearchBarLabel = textFieldInsideUISearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideUISearchBarLabel?.font = UIFont(name: "Open Sans", size: 15)
        textFieldInsideUISearchBarLabel?.textColor = UIColor.black
    }
    
    // MARK: - Button Actions
    
    @IBAction func findSchoolGoButton(_ sender: AnyObject) {
        
        dismissKeyboard()
        
        // Checks to see if the user inputted anything in the searchBar.
        if searchBar.text != "" {
            
            saveSchoolVoodoo(schoolName: searchBar.text! as String)
            
            // Transitions to the main board screen.
            self.tabBarController?.selectedIndex = 2
        }
        
        // Returns the fields back to blank so any return to the screen won't have the current user's information.
        emailField.text = ""
        passwordField.text = ""
        searchBar.text = ""
        
        // Hides the findSchoolAlert.
        findSchoolAlert.alpha = 0
    }
    
    @IBAction func goButtonAction(_ sender: AnyObject) {
        
        dismissKeyboard()
        firebaseLoginSignupVoodoo(email: emailField.text!, password: passwordField.text!)
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
     Firebase authorization checks to see if the user has an account by trying to recognize the email and password. If it isn't found, an error will tell us that there is no account with those credentials. An account will then be created.
     
     - Parameter email: The email from the emailField.text (provided by the user).
     - Parameter password: The password from the passwordField.text (provided by the user).
     
     - Todo: Create alerts to notify the user what *specific* error occurs.
     */
    func firebaseLoginSignupVoodoo(email: String, password: String) {
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            
            if error == nil {
                
                // Success! The user has logged in!
                
                // Transitions to the main board screen.
                self.tabBarController?.selectedIndex = 2
                
            } else {
                
                // Error!
                
                // Firebase couldn't match the credentials of the account to an existing one, so a new account is created *after* the user is asked if an account should be created.
                if error?._code == STATUS_ACCOUNT_NONEXIST {
                    
                    // Create an alert to ask the user if a new account should be created.
                    let notice = SCLAlertView()
                    
                    notice.addButton("Yes!") {
                        
                        // The user has given permission to create him/her an account.
                        
                        // Firebase does some voodoo to create the user an account with the provided information.
                        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                            
                            if error != nil {
                                
                                // Error! Something went wrong creating an account.
                                SCLAlertView().showError("Oh no!", subTitle: "Pluto could not create an account for you at this time.")
                                
                            } else {
                                
                                // Success! The user has been created!
                                
                                self.saveUser(user: user!, userID: (user?.uid)!, email: email, password: password, providerID: (user?.providerID)!)
                                self.callFindSchoolAlert()
                            }
                        })
                    }
                    
                    notice.showInfo("Hey!", subTitle: "Pluto couldn't find an account with these credentials. Should we create you a new account?", closeButtonTitle: "No, I made a mistake!")
                    
                } else {
                    
                    // Error! This means something went wrong that wasn't caught above.
                    // SCLAlertView().showError("Oh no!", subTitle: "Pluto could not log you in at this time because of an unknown error.")
                }
            }
        })
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
    
    /**
     Saves the user to the Firebase database.
     
     - Parameter user: The user that was created by Firebase and successfully authorized.
     - Parameter userID: The user's unique ID.
     - Parameter email: The user's email inputted in the emailField.text.
     - Parameter providerID: How the user signed up (Firebase, Facebook, Google, etc.).
     */
    func saveToDatabaseVoodoo(user: FIRUser?, userID: String, email: String, providerID: String) {
        
        if let user = user {
            
            // Creates a dictionary for the user information that will be saved to the database.
            let userData = ["provider": providerID,
                            "email": email]
            
            DataService.ds.createFirebaseDBUser(uid: user.uid, userData: userData)
        }
    }
    
    // MARK: - Helpers
    
    /**
     Simple animation that fades the view given in or out.
     
     - Parameter view: The element that the animation will be done on.
     - Parameter alpha: How transparent the view should be after the animation plays out.
     */
    func animateFade(view: UIView, alpha: CGFloat) {
        
        UIView.animate(withDuration: 0.3) {
            
            view.alpha = alpha
        }
    }
    
    /**
     Called when the user has successfully signed up.
     
     Brings up an alert that allows the user to find their school.
     */
    func callFindSchoolAlert() {
        
        parseSchoolsCSV()
        
        // Brings up the alert.
        animateFade(view: findSchoolAlert, alpha: 1.0)
    }
    
    /**
     Dismisses the keyboard!
     
     Just put whatever textfields you want included here in the function.
     */
    func dismissKeyboard() {
        
        // Dismisses the keyboard for these text fields.
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
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
    
    /**
     Saves the user's email and password to NSUserDefaults to bypass login for future use.
     
     - Parameter email: The email from the emailField.text (provided by the user).
     - Parameter password: The password from the passwordField.text (provided by the user).
     */
    func saveDefault(email: String, password: String) {
        
        let userDefaults = UserDefaults.standard
        
        // Save the email and password into userDefaults.
        userDefaults.set(email, forKey: "email")
        userDefaults.set(password, forKey: "password")
    }
    
    /**
     This is a gateway function; it's only purpose is to avoid repetitive function calling when saving the user.
     
     - Parameter user: The user that was created by Firebase and successfully authorized.
     - Parameter userID: The user's unique ID.
     - Parameter email: The user's email inputted in the emailField.text.
     - Parameter password: The user's password inputted in the passwordField.text.
     - Parameter providerID: How the user signed up (Firebase, Facebook, Google, etc.).
     */
    func saveUser(user: FIRUser?, userID: String?, email: String, password: String, providerID: String) {
        
        saveToDatabaseVoodoo(user: user, userID: userID!, email: email, providerID: providerID)
        saveDefault(email: email, password: password)
    }
    
    // MARK: - Search Bar Functions
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        // This function is called when the user clicks on the searchBar to begin editing.
        
        // Hides the findSchoolGoButton while the user is typing so the searchPreview can be presented without the button over it.
        animateFade(view: findSchoolGoButton, alpha: 0)
    }
    
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
        
        // Brings back the findSchoolGoButton.
        animateFade(view: findSchoolGoButton, alpha: 1.0)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        // This function is called after the user clicks the return key on the keyboard, indicating editing has ended.
        
        // Beings the findSchoolGoButton back.
        animateFade(view: findSchoolGoButton, alpha: 1.0)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Returns only the number of suggestions the filter has for the user's query.
        return filteredBoards.count
    }
    
    // MARK: - Text Field Functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Dismisses the keyboard.
        textField.resignFirstResponder()
        
        return true
    }
}
