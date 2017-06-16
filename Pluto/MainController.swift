//
//  MainViewController.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/2/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps
import GooglePlaces
import SwiftySound

class MainController: UIViewController, UIGestureRecognizerDelegate, UINavigationControllerDelegate, ZoomToCurrentLocDelegate {
        
    // MARK: - Variables
    
    /* Map */
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    /// A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    var geoFire: GeoFire!
    
    /* UI */
    var searchBar: SearchBar!
    var resultsView: UITableView!
    var userButton: Button!
    var blurView: UIVisualEffectView!
    var vibrancyView: UIVisualEffectView!
    var eventDetailView: EventView!
    var menuBar: MenuBar!
    
    /* Events */
    /// Holds the data for all the events under the current board.
    var events = [Event]()
    /// Holds all the filtered board titles as the filtering function does its work.
    var filteredEvents = [Event]()
    
    /* Flags */
    var imageSelected = false
    /// Lets us know when user is typing in the searchBar.
    var inSearchMode = false
    /// Lets us know that the map has opened for the first time and we need to zoom to the user's location.
    var mapCenteredOnce = false
    
    /* Other */
    /// Holds all event pictures.
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    var imagePicker: UIImagePickerController!
    var profileImage = UIImage()
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Initialization */
        
        // Image Picker
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true // Allows the user to select which portion of their selected image is to be used.
        
        // Location Manager & Places
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        placesClient = GMSPlacesClient.shared()
        
        // Map View
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true // Allows the map API to use the user's location.
        mapView.delegate = self
        
        do {
            
            // Set the map style by passing the URL of the local file.
            
            if let styleURL = Bundle.main.url(forResource: "mapstyle", withExtension: "json") {
                
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                
            } else {
                
                print("ERROR: can't find the mapstyle.json file for the mapView.")
            }
            
        } catch {
            
            print("ERROR: can't load the mapstyle.json file for the mapView. Details: \(error)")
        }
        
        view.addSubview(mapView)
        
        // Search Bar
        searchBar = SearchBar()
        searchBar.frame = CGRect(x: self.view.bounds.width / 2, y: 100, width: 320, height: 60)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search for an event"
        searchBar.delegate = self
        
        self.view.addSubview(searchBar)
        addSearchBarConstraints()
        
        // Results View
        resultsView = UITableView()
        resultsView.frame = CGRect(x: self.view.bounds.width / 2, y: 100, width: 320, height: 150)
        resultsView.register(ResultCell.self, forCellReuseIdentifier: "cell")
        resultsView.backgroundColor = UIColor.clear
        resultsView.separatorColor = UIColor.clear
        
        resultsView.translatesAutoresizingMaskIntoConstraints = false
        resultsView.dataSource = self
        resultsView.delegate = self
        
        // Note: resultsView should not be added to the view until after the user starts typing in the search bar.
        
        DataService.ds.REF_CURRENT_USER.observeSingleEvent(of: .value, with: { (snapshot) in
            
            /// Holds each dictionary under the current user in Firebase.
            let value = snapshot.value as? NSDictionary
            let image = value?["image"] as? String
            
            if image == "none" {
                
                /* Ask the user to upload an image. */
                
                let notice = SCLAlertView()
                
                notice.addButton("Select photo") {
                    
                    /* Open image picker. */
                    
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
                
                notice.showInfo("Welcome to Pluto!", subTitle: "Please pick a profile picture for yourself.")
                
            } else {
                
                self.downloadProfileImage(image: image!)
            }
            
        }) { (error) in
            
            // Error! The information could not be received from Firebase.
            SCLAlertView().showError("Oh no!", subTitle: "Pluto couldn't find your information.")
        }
        
        // User Button
        userButton = Button()
        userButton.frame = CGRect(x: self.mapView.center.x, y: self.mapView.center.y, width: 75, height: 75)
        userButton.translatesAutoresizingMaskIntoConstraints = false
        userButton.cornerRadius = userButton.frame.height / 2
        userButton.addTarget(self, action: #selector(MainController.userButtonTapped(sender:)), for: .touchUpInside)
        userButton.backgroundColor = UIColor.black
        self.view.addSubview(userButton)
        addUserButtonConstraints()
        
        // Menu Bar
        menuBar = MenuBar()
        menuBar = Bundle.main.loadNibNamed("MenuBar", owner: self, options: nil)?[0] as? MenuBar
        menuBar.center = CGPoint(x: self.view.center.x, y: self.userButton.center.y)
        menuBar.translatesAutoresizingMaskIntoConstraints = false
        menuBar.zoomDelegate = self
        self.view.insertSubview(menuBar, belowSubview: userButton)
        addMenuBarConstraints()
        
        /* Configuration */
        
        grabEventData()
        geoFire = GeoFire(firebaseRef: DataService.ds.REF_EVENT_LOCATIONS)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(true, animated: true) // Hides the navigation bar.
        
        // Hide empty cells.
        resultsView.tableFooterView = UIView(frame: .zero)
        resultsView.tableFooterView?.isHidden = true
    }
    
    // MARK: - Actions
    
    /**
     Action for when the user taps on the userButton.
     
     - Author: Faisal M. Lalani
     
     - Todo: send the user to the user's profile.
     
     - Parameter sender: the button tapped.
     
     - Note: For Version 0.1, this button will prompt the user for log out.
     */
    func userButtonTapped(sender: Button!) {
        
        let notice = SCLAlertView() // Initialize a notice.
        
        notice.addButton("Yes", action: {
            
            // Clear the user defaults so the user doesn't auto-login to their account next time.
            let userDefaults = UserDefaults.standard
            userDefaults.set(nil, forKey: "email")
            
            try! Auth.auth().signOut() // Sign out using Firebase.
            
            self.switchController(controllerID: "Login") // Switch to the login screen.
        })
        
        notice.showInfo("Log out?", subTitle: "", closeButtonTitle: "No") // Present the notice.
    }
    
    // MARK: - Helpers
    
    /**
     This is a delegate function called from a subview (more specficially, the menuBar). It centers the map on a location the user found when searching using Google's location search.
     
     - Author: Faisal M. Lalani
     
     - Parameter loc: the coordinate to zoom to.
     */
    func centerOnSearchedLoc(loc: CLLocationCoordinate2D) {
        
        self.zoomTo(lat: loc.latitude, lng: loc.longitude)
    }
    
    /**
     This is a delegate function called from a subview (more specficially, the menuBar). It centers the map on the user's current location.
     
     - Author: Faisal M. Lalani
     */
    func centerOnUserLoc() {
        
        self.zoomTo(lat: (self.mapView.myLocation?.coordinate.latitude)!, lng: (self.mapView.myLocation?.coordinate.longitude)!)
    }
    
    /**
     Adds a blurred and vibrant UIView using Apple's Effect tools. Called when another view is about to be added on top of the map.
     
     - Author: Faisal M. Lalani
     */
    func createBlurView() {
        
        // Initialize the effects to be added to the UIView.
        // Note: we need a second view for the vibrancy effect.
        let blurEffect = UIBlurEffect(style: .dark)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        blurView = UIVisualEffectView(effect: blurEffect)
        vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        blurView.frame = mapView.bounds
        vibrancyView.frame = blurView.bounds
        blurView.translatesAutoresizingMaskIntoConstraints = false
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(blurView)
        blurView.contentView.addSubview(vibrancyView)
        
        // Add a gesture to the view that allows the user to double tap anywhere to dismiss this view and the view on top of it.
        let tap = UITapGestureRecognizer(target: self, action: #selector(MainController.removeView))
        tap.delegate = self
        tap.numberOfTapsRequired = 2
        vibrancyView.addGestureRecognizer(tap) // Add the gesture to the vibrancy view because it's technically on top of the blur view.
        
        addBlurViewConstraints()
        addVibrancyViewConstraints()
    }
    
    /**
     Removes the view on top of the map with a nifty animation.
     
     - Author: Faisal M. Lalani
     
     - Todo: find an easier way to dismiss the keyboards.
     */
    func removeView() {
        
        // First make sure the view is there to begin with.
        if eventDetailView != nil {
            
            // Dismiss the keyboards of the text fields in the view.
            eventDetailView.titleField.resignFirstResponder()
            eventDetailView.timeStartField.resignFirstResponder()
            eventDetailView.timeEndField.resignFirstResponder()
            AnimationEngine.animateToPosition(view: eventDetailView, position: AnimationEngine.offScreenRightPosition)
            eventDetailView = nil
        }
        
        vibrancyView.alpha = 0
        blurView.alpha = 0
        vibrancyView = nil
        blurView = nil
    }
    
    /**
     Switches to the view controller specified by the parameter.
     
     - Author: Faisal M. Lalani
     
     - Parameter controllerID: the ID of the controller to switch to.
     */
    func switchController(controllerID: String) {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : UIViewController = mainStoryboard.instantiateViewController(withIdentifier: controllerID) as UIViewController
        self.present(vc, animated: true, completion: nil)
    }
    
    /**
     Zooms to a point using the latitude and longitude passed in.
     
     - Author: Faisal M. Lalani
     
     - Parameter lat: the latitude of the coordinate to zoom to.
     - Parameter lng: the longitude of the coordinate to zoom to.
     */
    func zoomTo(lat: CLLocationDegrees, lng: CLLocationDegrees) {
        
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: lng, zoom: zoomLevel)
        self.mapView.animate(to: camera)
    }
    
    // MARK: - Firebase
    
    /**
     Goes into Firebase storage to download the user's set profile image.
     
     - Parameter image: a string that holds a reference to where the image is stored in Firebase storage.
     */
    func downloadProfileImage(image: String) {
        
        /// Holds the event image grabbed from the cache.
        if let img = MainController.imageCache.object(forKey: image as NSString) {
            
            self.userButton.setImage(img, for: .normal)
            
        } else {
            
            /* If it doesn't download from the cache for some reason, just download it from Firebase. */
            
            let ref = Storage.storage().reference(forURL: image)
            
            ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
                
                if error != nil {
                    
                    print("ERROR: unable to download photo from Firebase. Details: \(error.debugDescription)")
                    
                } else {
                    
                    if let imageData = data {
                        
                        if let img = UIImage(data: imageData) {
                            
                            self.userButton.setImage(img, for: .normal)
                        }
                    }
                }
            })
        }
    }
    
    /**
     Uses the keys received from under the current board's data reference to find and grab the data relating to the keys.
     
     - Author: Faisal M. Lalani
     */
    func grabEventData() {
        
       // let currentDate = Date()
        
//        let formatter = DateFormatter()
//        formatter.dateStyle = DateFormatter.Style.medium
//        formatter.timeStyle = DateFormatter.Style.short
        
        DataService.ds.REF_EVENTS.observe(.value, with: { (snapshot) in
            
            self.events = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        
                        /* The event belongs under this board. */
                        
                        let event = Event(eventKey: key, eventData: eventDict) // Format the data using the Event model.
                        
                        self.events.append(event) // Add the event to the events array.
                        self.saveEventImageToCache(eventImageURL: event.imageURL)
                        
//                        let eventStartTime = formatter.date(from: event.timeStart)
//
//                        if eventStartTime! > currentDate {
//
////                            self.events.append(event) // Add the event to the events array.
////                            print("Added")
////                            self.saveEventImageToCache(eventImageURL: event.imageURL)
//                        }
                    }
                }
            }
            
            //self.callShowEvents()
            self.mapCenteredOnce = true
        })
    }
    
    func saveEventImageToCache(eventImageURL: String) {
                
        let ref = Storage.storage().reference(forURL: eventImageURL)
        
        ref.getData(maxSize: 2 * 1024 * 1024, completion: { (data, error) in
            
            if error != nil {
                
                /* ERROR: Unable to download photo from Firebase storage. */
                
            } else {
                
                /* SUCCESS: Image downloaded from Firebase storage. */
                
                if let imageData = data {
                    
                    if let img = UIImage(data: imageData) {
                        
                        MainController.imageCache.setObject(img, forKey: eventImageURL as NSString) // Save to image cache.
                        
                    }
                }
            }
            
            self.callShowEvents()
        })
    }
    
    /**
     Called when the user selects an image and attempts to save.
     
     The image is saved as data and an ID is generated that allows it to be saved in the Firebase storage.
     */
    func uploadProfileImage() {
        
        // Grabs the image from the profileImageView and compresses it by the scale given.
        if let imageData = UIImageJPEGRepresentation(profileImage, 0.2) {
            
            /// Holds a unique id for the image being uploaded.
            let imageUID = NSUUID().uuidString
            
            // Tells Firebase storage what file type is being uploaded.
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            // Opens up the profile pics folder in the Firebase storage so the image can be uploaded.
            DataService.ds.REF_PROFILE_PICS.child(imageUID).putData(imageData, metadata: metadata) { (metadata, error) in
                
                if error != nil {
                    
                    // ERROR: The image could not be uploaded to Firebase storage.
                    
                } else {
                    
                    // SUCCESS: Uploaded image to Firebase storage.
                    
                    /// Holds the imageURL that can be used as a reference in the database.
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    self.updateUserData(imageURL: downloadURL!)
                }
            }
        }
    }
    
    /**
     Called when the picture the user selected successfully uploads to the Firebase storage.
     
     Here the imageURL is saved under the current user's data in the Firebase database.
     
     - Parameter imageURL: A string that holds a reference to where the image is stored in the Firebase storage.
     */
    func updateUserData(imageURL: String) {
        
        /// Holds the reference to the user's image key in the database.
        let userProfileRef = DataService.ds.REF_CURRENT_USER.child("image")
        // Sets the value for the image key to the parameter (imageURL).
        userProfileRef.setValue(imageURL)
        
        // Sets the imageSelected false to indicate the image is done uploading and can be updated again.
        imageSelected = false
    }
    
    /**
     Uses the subtitle of the marker tapped (which, sneakily, is the key of the event the marker refers to) to grab the event's full details.
     
     - Author: Faisal M. Lalani
     
     - Parameter eventKey: the key of the event to find.
     */
    func markerEventMatch(eventKey: String) -> Event? {
        
        for event in self.events {
            
            if event.eventKey == eventKey {
                
                return event
            }
        }
        
        return nil
    }
}

extension MainController: CLLocationManagerDelegate, GMSMapViewDelegate {
    
    // MARK: - Helpers
    
    /**
     Summons the detail view for the specific event passed through.
     
     - Author: Faisal M. Lalani
     
     - Todo: just fix this mess of a function.
     
     - Parameter isNewEvent: lets us know if the detail view needs to be blank so the user can create a new event.
     - Parameter coordinate: optional; the coordinate of the event tapped.
     - Parameter event: optional; the event tapped.
     */
    func callEventDetail(isNewEvent: Bool, coordinate: CLLocationCoordinate2D? = nil, event: Event? = nil) {
        
        createBlurView() // Adds a blur to seperate the map and the view.
        
        // Initialization of the detail view.
        eventDetailView = Bundle.main.loadNibNamed("EventView", owner: self, options: nil)?[0] as? EventView
        eventDetailView.center = AnimationEngine.offScreenRightPosition
        eventDetailView.isNewEvent = isNewEvent
        
        if coordinate != nil {
            
            eventDetailView.setEventLocation(coordinate: coordinate!)
        }
        
        let userID = Auth.auth().currentUser?.uid
        
        if event != nil {
            
            eventDetailView.event = event
            eventDetailView.eventKey = event?.eventKey
            eventDetailView.eventImageURL = event?.imageURL
            eventDetailView.setEventImage()
            eventDetailView.titleField.text = event?.title
            eventDetailView.timeStartField.text = event?.timeStart
            eventDetailView.timeEndField.text = event?.timeEnd
            eventDetailView.countLabel.text = "\((event?.count)!)"
            
            if event?.creator == userID {
                
                eventDetailView.isEventCreator = true
            }
        }
        
        AnimationEngine.animateToPosition(view: eventDetailView, position: AnimationEngine.centerPosition)
        self.view.addSubview(eventDetailView)
    }
    
    /**
     Grabs the user's location and passes it through to the showEventsOnMap function.
     
     - Author: Faisal M. Lalani
     
     - Note: this is a "gateway" function created because this code was being repeated.
     */
    func callShowEvents() {
        
        guard let lat = self.mapView.myLocation?.coordinate.latitude,
            let lng = self.mapView.myLocation?.coordinate.longitude else { return }
        
        self.showEventsOnMap(location: CLLocation(latitude: lat, longitude: lng))
    }
    
    /**
     Geofire does its work and pulls event locations from Firebase and adds them to the map.
     
     - Author: Faisal M. Lalani
     
     - Todo:
     
     - Parameter location: the location to query.
     
     - Note: does location need to be a parameter?
     
     - SeeAlso: 'callShowEvents()'
     */
    func showEventsOnMap(location: CLLocation) {
        
        mapView.clear()
        
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        _ = circleQuery?.observe(.keyEntered, with: { (key, location) in
            
            if let key = key, let location = location {
                
                let event = self.markerEventMatch(eventKey: key)
                let eventImageURL = event?.imageURL
                
                var eventImage = MainController.imageCache.object(forKey: eventImageURL! as NSString)
                
                let markerView = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
                
                if eventImage != nil {
                    
                    eventImage = self.resizeImageWithAspect(image: eventImage!, scaledToMaxWidth: 70.0, maxHeight: 80.0)
                }
                
                markerView.image = eventImage;
                markerView.contentMode = .scaleAspectFill
                markerView.layer.cornerRadius = 30.0
                markerView.layer.masksToBounds = true
                
                let marker = GMSMarker()
                marker.tracksInfoWindowChanges = true
                marker.position = location.coordinate
                marker.title = event?.title
                marker.snippet = event?.eventKey
                marker.icon = eventImage
                marker.iconView?.frame = markerView.frame
                marker.iconView = markerView
                marker.appearAnimation = .pop
                Sound.play(file: "pop.mp3")
                marker.map = self.mapView
            }
        })
    }
    
    // MARK: - Location Manager
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Handle incoming location events.
        
        let location: CLLocation = locations.last!
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView.isHidden {
            
            mapView.isHidden = false
            mapView.camera = camera
            
        } else {
            
            mapView.animate(to: camera)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        // Handle authorization for the location manager.
        
        switch status {
            
        case .restricted:
            
            print("INFO: Location access was restricted.")
            
        case .denied:
            
            print("INFO: User denied access to location.")
            
            /* Display the map using the default location. */
            mapView.isHidden = false
            
        case .notDetermined:
            
            print("INFO: Location status not determined.")
            
        case .authorizedAlways: fallthrough
            
        case .authorizedWhenInUse:
            
            print("INFO: Location status is OK.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        // Handle location manager errors.
        
        locationManager.stopUpdatingLocation()
        
        print("ERROR: \(error)")
    }
    
    // MARK: - Map View
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        
        // Allow the user to create an event.
        
        callEventDetail(isNewEvent: true, coordinate: coordinate)
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        // Allow the user to view the event they tapped on's details.
        
        let event = markerEventMatch(eventKey: marker.snippet!)
        callEventDetail(isNewEvent: false, event: event)
        
        return true
    }
}

extension MainController: UIImagePickerControllerDelegate {
    
    // MARK: - Image Picker
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // This function is called when something in the imagePicker is selected.
        
        // "Media" means it can be a video or an image.
        // Checks to make sure it is an image the user picked.
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            // Sets the profileImage to the selected image.
            self.profileImage = image
            self.userButton.setImage(image, for: .normal)
            
            // Sets the imageSelected to true because the user is now updating his profile picture and Pluto needs to save it.
            imageSelected = true
            self.uploadProfileImage()
        }
        
        // Hides the imagePicker.
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    /**
     Resizes the image passed through without losing quality.
     
     - Author: StackOverflow
     
     - Parameter image: the image to shrink.
     - Parameter size: the size to shrink the image to.
     */
    func _resizeWithAspect_doResize(image: UIImage, size: CGSize) -> UIImage {
        
        if UIScreen.main.responds(to: #selector(NSDecimalNumberBehaviors.scale)) {
            
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            
        } else {
            
            UIGraphicsBeginImageContext(size)
        }
        
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    /**
     Provides values for resizing.
     
     - Author: StackOverflow
     
     - Parameter image: the image to shrink.
     - Parameter width: the width to shrink the image width to.
     - Parameter height: the width to shrink the image height to.
     */
    func resizeImageWithAspect(image: UIImage, scaledToMaxWidth width: CGFloat, maxHeight height: CGFloat) -> UIImage {
        
        let oldWidth = image.size.width;
        let oldHeight = image.size.height;
        
        let scaleFactor = (oldWidth > oldHeight) ? width / oldWidth : height / oldHeight;
        
        let newHeight = oldHeight * scaleFactor;
        let newWidth = oldWidth * scaleFactor;
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        return self._resizeWithAspect_doResize(image: image, size: newSize);
    }
    
}

extension MainController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        let lat = place.coordinate.latitude
        let lng = place.coordinate.longitude
        
        let camera = GMSCameraPosition.camera(withLatitude: lat ,longitude: lng , zoom: zoomLevel)
        self.mapView.animate(to: camera)
        
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        
        print("ERROR: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension MainController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let searchBarText = searchBar.text!.uppercased()
        
        if searchBarText == "" {
            
            inSearchMode = false // This means the user is NOT typing in the searchBar.
            
            resultsView.removeFromSuperview()
            
        } else {
            
            inSearchMode = true // This means the user is typing in the searchBar.
            
            self.view.addSubview(resultsView)
            self.addResultsViewConstraints()
            
            filteredEvents = events.filter({$0.title.uppercased().range(of: searchBarText) != nil})
            resultsView.reloadData() // Reloads the searchPreview as the filtering occurs.
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        /* This function is called when the user clicks the return key while editing of the searchBar is enabled. */
        
        searchBar.resignFirstResponder() // Dismisses the keyboard for the search bar.
        
        /* Checks to see if the user inputted anything in the search bar. */
        if searchBar.text != "" {
            
            /* Zoom to the event's location. */
            
            /* Bring up the createEventView. */
        }
        
        searchBar.text = "" // Returns the bar back to blank so any return to the screen won't have the current user's information.
    }
}

extension MainController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1 // We only need 1 section.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return filteredEvents.count // Returns only the number of suggestions the filter has for the user's query.
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ResultCell
                
        let event = filteredEvents[indexPath.row]
        
        cell.configureCell(event: event)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let event = filteredEvents[indexPath.row]
        
        resultsView.removeFromSuperview()
        
        searchBar.resignFirstResponder()
        searchBar.text = ""
        
        let eventLocRef = DataService.ds.REF_EVENT_LOCATIONS.child(event.eventKey)
        
        eventLocRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            /// Holds each dictionary under the current user in Firebase.
            let value = snapshot.value as? NSDictionary
            let loc = (value?["l"] as? NSArray)!
            
            let lat = loc[0] as! CLLocationDegrees
            let lng = loc[1] as! CLLocationDegrees
            
            self.zoomTo(lat: lat, lng: lng)
            
            self.callEventDetail(isNewEvent: false, event: event)
        })
    }
}

/* Constraint Hell */

extension MainController {
    
    func addSearchBarConstraints() {
        
        let heightConstraint = NSLayoutConstraint(
            item: searchBar,
            attribute: NSLayoutAttribute.height,
            relatedBy: NSLayoutRelation.equal,
            toItem: nil,
            attribute: NSLayoutAttribute.notAnAttribute,
            multiplier: 1.0,
            constant: 60
        )
        
        searchBar.addConstraint(heightConstraint)
        
        let leftConstraint = NSLayoutConstraint(
            item: searchBar,
            attribute: NSLayoutAttribute.leading,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.leading,
            multiplier: 1.0,
            constant: 30
        )
        
        self.view.addConstraint(leftConstraint)
        
        let rightConstraint = NSLayoutConstraint(
            item: searchBar,
            attribute: NSLayoutAttribute.trailing,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.trailing,
            multiplier: 1.0,
            constant: -30
        )
        
        self.view.addConstraint(rightConstraint)
        
        let topConstraint = NSLayoutConstraint(
            item: searchBar,
            attribute: NSLayoutAttribute.top,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.top,
            multiplier: 1,
            constant: 75
        )
        
        self.view.addConstraint(topConstraint)
    }
    
    func addResultsViewConstraints() {
        
        let heightConstraint = NSLayoutConstraint(
            item: resultsView,
            attribute: NSLayoutAttribute.height,
            relatedBy: NSLayoutRelation.equal,
            toItem: nil,
            attribute: NSLayoutAttribute.notAnAttribute,
            multiplier: 1.0,
            constant: 150
        )
        
        resultsView.addConstraint(heightConstraint)
        
        let leftConstraint = NSLayoutConstraint(
            item: resultsView,
            attribute: NSLayoutAttribute.leading,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.leading,
            multiplier: 1.0,
            constant: 30
        )
        
        self.view.addConstraint(leftConstraint)
        
        let rightConstraint = NSLayoutConstraint(
            item: resultsView,
            attribute: NSLayoutAttribute.trailing,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.trailing,
            multiplier: 1.0,
            constant: -30
        )
        
        self.view.addConstraint(rightConstraint)
        
        let topConstraint = NSLayoutConstraint(
            item: resultsView,
            attribute: NSLayoutAttribute.top,
            relatedBy: NSLayoutRelation.equal,
            toItem: searchBar,
            attribute: NSLayoutAttribute.top,
            multiplier: 1,
            constant: searchBar.frame.height
        )
        
        NSLayoutConstraint.activate([topConstraint])
    }
    
    func addUserButtonConstraints() {
        
        let heightConstraint = NSLayoutConstraint(
            item: userButton,
            attribute: NSLayoutAttribute.height,
            relatedBy: NSLayoutRelation.equal,
            toItem: nil,
            attribute: NSLayoutAttribute.notAnAttribute,
            multiplier: 1.0,
            constant: 75
        )
        
        userButton.addConstraint(heightConstraint)
        
        let widthConstraint = NSLayoutConstraint(
            item: userButton,
            attribute: NSLayoutAttribute.width,
            relatedBy: NSLayoutRelation.equal,
            toItem: nil,
            attribute: NSLayoutAttribute.notAnAttribute,
            multiplier: 1.0,
            constant: 75
        )
        
        userButton.addConstraint(widthConstraint)
        
        let rightConstraint = NSLayoutConstraint(
            item: userButton,
            attribute: NSLayoutAttribute.trailing,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.trailing,
            multiplier: 1.0,
            constant: -16
        )
        
        self.view.addConstraint(rightConstraint)
        
        let bottomConstraint = NSLayoutConstraint(
            item: userButton,
            attribute: NSLayoutAttribute.bottom,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.bottom,
            multiplier: 1,
            constant: -25
        )
        
        self.view.addConstraint(bottomConstraint)
    }
    
    func addMenuBarConstraints() {
        
        let heightConstraint = NSLayoutConstraint(
            item: menuBar,
            attribute: NSLayoutAttribute.height,
            relatedBy: NSLayoutRelation.equal,
            toItem: nil,
            attribute: NSLayoutAttribute.notAnAttribute,
            multiplier: 1.0,
            constant: 50
        )
        
        menuBar.addConstraint(heightConstraint)
        
        let leftConstraint = NSLayoutConstraint(
            item: menuBar,
            attribute: NSLayoutAttribute.leading,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.leading,
            multiplier: 1.0,
            constant: 25
        )
        
        self.view.addConstraint(leftConstraint)
        
        let rightConstraint = NSLayoutConstraint(
            item: menuBar,
            attribute: NSLayoutAttribute.trailing,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.trailing,
            multiplier: 1.0,
            constant: -self.userButton.frame.width + 10
        )
        
        self.view.addConstraint(rightConstraint)
        
        let bottomConstraint = NSLayoutConstraint(
            item: menuBar,
            attribute: NSLayoutAttribute.bottom,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.bottom,
            multiplier: 1,
            constant: -34
        )
        
        self.view.addConstraint(bottomConstraint)
    }
    
    func addBlurViewConstraints() {
        
        let leftConstraint = NSLayoutConstraint(
            item: blurView,
            attribute: NSLayoutAttribute.leading,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.leading,
            multiplier: 1.0,
            constant: 0
        )
        
        self.view.addConstraint(leftConstraint)
        
        let rightConstraint = NSLayoutConstraint(
            item: blurView,
            attribute: NSLayoutAttribute.trailing,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.trailing,
            multiplier: 1.0,
            constant: 0
        )
        
        self.view.addConstraint(rightConstraint)
        
        let topConstraint = NSLayoutConstraint(
            item: blurView,
            attribute: NSLayoutAttribute.top,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.top,
            multiplier: 1,
            constant: 0
        )
        
        self.view.addConstraint(topConstraint)
        
        let bottomConstraint = NSLayoutConstraint(
            item: blurView,
            attribute: NSLayoutAttribute.bottom,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.bottom,
            multiplier: 1,
            constant: 0
        )
        
        self.view.addConstraint(bottomConstraint)
    }
    
    func addVibrancyViewConstraints() {
        
        let leftConstraint = NSLayoutConstraint(
            item: vibrancyView,
            attribute: NSLayoutAttribute.leading,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.leading,
            multiplier: 1.0,
            constant: 0
        )
        
        self.view.addConstraint(leftConstraint)
        
        let rightConstraint = NSLayoutConstraint(
            item: vibrancyView,
            attribute: NSLayoutAttribute.trailing,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.trailing,
            multiplier: 1.0,
            constant: 0
        )
        
        self.view.addConstraint(rightConstraint)
        
        let topConstraint = NSLayoutConstraint(
            item: vibrancyView,
            attribute: NSLayoutAttribute.top,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.top,
            multiplier: 1,
            constant: 0
        )
        
        self.view.addConstraint(topConstraint)
        
        let bottomConstraint = NSLayoutConstraint(
            item: vibrancyView,
            attribute: NSLayoutAttribute.bottom,
            relatedBy: NSLayoutRelation.equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.bottom,
            multiplier: 1,
            constant: 0
        )
        
        self.view.addConstraint(bottomConstraint)
    }
}

