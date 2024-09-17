//
//  CustomAnnotation.swift
//  WeatherApp
//
//  Created by Venuka Valiveti on 13/09/24.
//

import Foundation
import MapKit

struct CustomAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String?
}
