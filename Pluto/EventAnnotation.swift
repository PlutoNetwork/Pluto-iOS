//
//  EventAnnotation.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 6/1/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class EventAnnotation: NSObject, MKAnnotation {
    
    var coordinate = CLLocationCoordinate2D()
    var eventKey: String
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, eventKey: String) {
        
        self.coordinate = coordinate
        self.eventKey = eventKey
        self.title = self.eventKey
        self.subtitle = self.eventKey
    }
}
