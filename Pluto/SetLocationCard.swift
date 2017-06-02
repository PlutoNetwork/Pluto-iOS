//
//  SetLocationCard.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 5/31/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import MapKit

protocol UpdateLocationDelegate {
    
    func setLocationField(text: String, coordinate: CLLocation)
}

class SetLocationCard: UIView, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var doneButton: Button!
    @IBOutlet weak var searchBar: SearchBar!
    
    var locationManager = CLLocationManager()
    var mapHasCenteredOnce = false
    
    var eventLocation = CLLocation()
    
    var locationDelegate: UpdateLocationDelegate?
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        setupView()
    }
    
    override func awakeFromNib() {
        
        setupView()
        
        searchBar.delegate = self
        
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        locationAuthStatus()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(SetLocationCard.handleTap(tap:)))
        tap.delegate = self
        mapView.addGestureRecognizer(tap)
    }
    
    func handleTap(tap: UITapGestureRecognizer) {
        
        mapView.removeAnnotations(mapView.annotations)
        let location = tap.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        eventLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        searchBar.text = "\(eventLocation)"
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
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if let loc = userLocation.location {
            
            if !mapHasCenteredOnce {
                
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
    }
    
    func setupView() {
        
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.shadowColor = SHADOW_COLOR.cgColor
        self.setNeedsLayout()
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        
        if searchBar.text != "" {
            
            locationDelegate?.setLocationField(text: searchBar.text!, coordinate: eventLocation)
        }
        
        self.removeFromSuperview()
    }
}

extension SetLocationCard: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        /* This function is called when the user clicks the return key while editing of the searchBar is enabled. */
        
        searchBar.resignFirstResponder() // Dismisses the keyboard for the search bar.
    }
}
