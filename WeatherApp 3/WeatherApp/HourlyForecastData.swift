//
//  HourlyForecastData.swift
//  WeatherApp
//
//  Created by Venuka Valiveti on 17/09/24.

import Foundation

// MARK: - WeatherForecast
struct HourlyWeatherForecast: Codable {
    let cod: String
    let message, cnt: Int
    var list: [HourlyList]
    let city: City
}

//MARK: - LIST
struct HourlyList: Codable {
    var id = UUID()
    let dt: Int
    let main: MainClass
    let weather: [Weather]
    let clouds: Clouds
    let wind: Wind
    let visibility: Int
    let pop: Double
    let rain: HourlyRain?
    let sys: Sys1
    let dtTxt: String
    

    enum CodingKeys: String, CodingKey {
        case dt, main, weather, clouds, wind, visibility, pop, rain, sys
        case dtTxt = "dt_txt"
    }
    
}

// MARK: - Rain
struct HourlyRain: Codable {
    let the1H: Double
    
    enum CodingKeys: String, CodingKey {
        case the1H = "1h"
    }
}


//MARK: - Sample Data 
struct HourlyWeatherData {
    let time: String
    let temperature: Double // Celsius
    let rainIntensity: Double // mm/h
    let rainProbability: Int // Percentage
    let windSpeed: Double // m/s
}
