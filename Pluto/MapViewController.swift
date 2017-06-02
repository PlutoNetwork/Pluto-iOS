//
//  MapViewController.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 5/30/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import FirebaseDatabase
import MapKit
import UIKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - OUTLETS

    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - VARIABLES
    
    let locationManager = CLLocationManager()
    var mapHasCenteredOnce = false
    
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!
    
    /// Holds all the event keys under the current board.
    var boardEventKeys = [String]()
    
    /// Holds the data for all the events under the current board.
    var events = [Event]()
    
    var annotationTitle: String!
    var annotationImage: UIImage!
    
    // MARK: - VIEW
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        grabBoardEvents()
        
        locationAuthStatus()
        
        geoFire = GeoFire(firebaseRef: DataService.ds.REF_CURRENT_BOARD_EVENTS)
        
    }
    
    /**
     *  Checks what events belong to the current board.
     */
    func grabBoardEvents() {
        
        DataService.ds.REF_CURRENT_BOARD_EVENTS.observe(.value, with: { (snapshot) in
            
            self.boardEventKeys = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    let key = snap.key
                    self.boardEventKeys.append(key) // Add the key to the keys array.
                }
            }
            
            self.grabEventData() // We call this here because it needs to happen AFTER the keys array is filled.
        })
    }
    
    func locationAuthStatus() {
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            
            mapView.showsUserLocation = true
            
        } else {
            
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            
            mapView.showsUserLocation = true
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        mapView.setRegion(coordinateRegion, animated: false)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if let loc = userLocation.location {
            
            if !mapHasCenteredOnce {
                
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
    }
    
    func showEventsOnMap(location: CLLocation) {
        
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        _ = circleQuery?.observe(.keyEntered, with: { (key, location) in
            
            print("*********")
            print("\(key!)")
            print("*********")
            
            if let key = key, let location = location {
                
                let anno = EventAnnotation(coordinate: location.coordinate, eventKey: key)
                //self.geoFire.removeKey(key)
                self.mapView.addAnnotation(anno)
            }
        })
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let annotationIdentifier = "Event"
        var annotationView: MKAnnotationView?
        
        /* Keeps the glowing blue dot that marks current user location. */
        
        if annotation.isKind(of: MKUserLocation.self) {
            
            return nil
            
        } else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
         
            annotationView = deqAnno
            annotationView?.annotation = annotation
            
        } else {
            
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        
        /* Customize the annotation. */
        
        if let annotationView = annotationView, let anno = annotation as? EventAnnotation {
            
            annotationView.canShowCallout = true
            
            let event = annoEventMatch(eventKey: anno.eventKey)
            
            anno.title = event?.title
            anno.subtitle = event?.timeStart
            
            let img = BoardController.imageCache.object(forKey: event?.imageURL as! NSString)
            let size = CGSize(width: 70, height: 70)
            UIGraphicsBeginImageContext(size)
            img?.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            imageView.image = resizedImage;
            imageView.layer.cornerRadius = imageView.layer.frame.size.width / 2
            imageView.layer.masksToBounds = true
            annotationView.frame = imageView.frame
            annotationView.addSubview(imageView)
            
            //annotationView.image = resizedImage
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "ic-directions"), for: .normal)
            annotationView.rightCalloutAccessoryView = btn
        }
        
        return annotationView
    }
    
    func annoEventMatch(eventKey: String) -> Event? {
        
        for event in self.events {
            
            if event.eventKey == eventKey {
                
                return event
            }
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        showEventsOnMap(location: loc)
    }
    
    /**
     *  Uses the keys received from under the current board's data reference to find and grab the data relating to the keys.
     */
    func grabEventData() {
        
        let currentDate = Date()
        
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.medium
        formatter.timeStyle = DateFormatter.Style.short
        
        DataService.ds.REF_EVENTS.observe(.value, with: { (snapshot) in
            
            self.events = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let eventDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        
                        for boardEventKey in self.boardEventKeys {
                            
                            if key == boardEventKey {
                                
                                /* The event belongs under this board. */
                                
                                let event = Event(eventKey: key, eventData: eventDict) // Format the data using the Event model.
                                
                                let eventStartTime = formatter.date(from: event.timeStart)
                                
                                if eventStartTime! > currentDate {
                                    
                                    self.events.append(event) // Add the event to the events array.
                                }
                                
                                break // We no longer need to check if the key matches another event.
                            }
                        }
                    }
                }
            }
            
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotations(self.mapView.annotations)
            
            let loc = CLLocation(latitude: self.mapView.centerCoordinate.latitude, longitude: self.mapView.centerCoordinate.longitude)
            
            self.showEventsOnMap(location: loc)
        })
    }

    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let anno = view.annotation as? Event {
            
            var place: MKPlacemark?
            
            if #available(iOS 10.0, *) {
                
                place = MKPlacemark(coordinate: anno.coordinate)
                
            } else {
                
                place = MKPlacemark(coordinate: anno.coordinate, addressDictionary: nil)
            }
            
            let destination = MKMapItem(placemark: place!)
            destination.name = "Event"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            
            MKMapItem.openMaps(with: [destination], launchOptions: options)
        }
    }
    
    @IBAction func centerOnUserButton(_ sender: Any) {
        
        mapView.setUserTrackingMode(.follow, animated: true)
    }
}
