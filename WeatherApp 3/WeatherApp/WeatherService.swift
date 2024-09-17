//
//  WeatherService.swift
//  WeatherApp
//
//  Created by Venuka Valiveti on 13/09/24.


import Foundation
import Combine

protocol WeatherServiceProtocol {
    func fetchWeather(for city: String) -> AnyPublisher<WeatherResponse, WeatherError>
    func fetchForecast(lat: Double, lon: Double) -> AnyPublisher<WeatherForecast, WeatherError>
    func hourlyForecastWeather(lat: Double, lon: Double) -> AnyPublisher<HourlyWeatherForecast, WeatherError>
}

class WeatherService: WeatherServiceProtocol {
    
    let apiKey = "231901e3a63cf94560cf49cfa6ae79d7"
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    func fetchWeather(for city: String) -> AnyPublisher<WeatherResponse, WeatherError> {
        
        let urlString = "\(baseURL)?q=\(city)&appid=\(apiKey)"
        //&units=metric"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: WeatherError.invalidCity)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .mapError { error in
                WeatherError.networkError
            }
            .eraseToAnyPublisher()
    }
    
    
    
    func fetchForecast(lat: Double, lon: Double) -> AnyPublisher<WeatherForecast, WeatherError> {
        
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: WeatherError.invalidCity)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherForecast.self, decoder: JSONDecoder())
            .mapError { error in
                    WeatherError.networkError
            }
            .eraseToAnyPublisher()
    }
    
    
    func hourlyForecastWeather(lat: Double, lon: Double) -> AnyPublisher<HourlyWeatherForecast, WeatherError> {
        let urlString = "https://api.openweathermap.org/data/2.5/forecast/hourly?lat=\(lat)&lon=\(lon)&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: WeatherError.invalidCity)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: HourlyWeatherForecast.self, decoder: JSONDecoder())
            .mapError { error in
                    .networkError
            }
            .eraseToAnyPublisher()
        
    }
    
}



