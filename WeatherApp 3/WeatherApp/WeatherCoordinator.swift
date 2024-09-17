//
//  WeatherCoordinator.swift
//  WeatherApp
//
//  Created by Venuka Valiveti on 13/09/24.
//

import Foundation
import SwiftUI

protocol WeatherCoordinatorProtocol {
    func start() ->  AnyView
}

class WeatherCoordinator: WeatherCoordinatorProtocol {
    
    private let weatherViewModel: WeatherViewModel
    
    init(weatherViewModel: WeatherViewModel) {
        self.weatherViewModel = weatherViewModel
    }
    
    func start() -> AnyView {
        return AnyView(WeatherView())
    }
}


