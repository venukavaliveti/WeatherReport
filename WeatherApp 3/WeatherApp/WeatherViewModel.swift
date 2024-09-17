//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by Venuka Valiveti on 13/09/24.
//


import SwiftUI
import Combine
import CoreLocation
import MapKit

class WeatherViewModel: ObservableObject {
    @Published var weatherData: WeatherResponse?
    @Published var weatherForecastData:WeatherForecast?
    @Published var forecastData:[List] = []
    @Published var hourlyForecastData:HourlyWeatherForecast?
    @Published var cityName:String = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let weatherService: WeatherServiceProtocol
    private var cache = NSCache<NSString, UIImage>()
    
    @Published var isExpand = false
    @Published var region: MKCoordinateRegion
    @Published var annotations: [CustomAnnotation] = []
    private var locationManager = CLLocationManager()
    
    // Inject the service via initializer (Dependency Injection)
    init(weatherService: WeatherServiceProtocol = WeatherService()) {
        self.weatherService = weatherService
        
        region = MKCoordinateRegion(
            //center: CLLocationCoordinate2D(latitude: 0.00, longitude: 0.00),
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.00, longitudeDelta: 0.00)
        )
        locationManager.requestWhenInUseAuthorization()
    }
    
    //MARK: - Fetch weather for a city
    func fetchWeather(for city: String) {
        isLoading = true
        weatherService.fetchWeather(for: city)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in //[weak self]
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch completion {
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    case .finished:
                        break
                    }
                }
                
            }, receiveValue: { weatherResponse in
                DispatchQueue.main.async {
                    self.weatherData = weatherResponse
                    self.errorMessage = nil
                    self.cityName = ""
                    UserDefaults.standard.set(city, forKey: "lastCity")
                    
                    self.fetchForecast(lat: weatherResponse.coord.lat, lon: weatherResponse.coord.lon)
                    //self.fetchHourlyWeatherData(lat: weatherResponse.coord.lat, lon: weatherResponse.coord.lon)
                }
                
            })
            .store(in: &self.cancellables)
    }
    
    //MARK: - Find 8-Day Forecast data based on longitude and latidute
    
    func fetchForecast(lat: Double, lon: Double) {
        weatherService.fetchForecast(lat: lat, lon: lon)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                DispatchQueue.main.async {
                    switch completion {
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    case .finished:
                        break
                    }
                }
                
            }, receiveValue: { forecastResponse in
                DispatchQueue.main.async {
                    self.weatherForecastData = forecastResponse
                    
                    self.forecastData.removeAll()
                    
                    for i in self.weatherForecastData?.list ?? []{
                        let datePart = i.dtTxt.split(separator: " ").first ?? ""
                        
                        if self.forecastData.contains(where: { object in
                            object.dtTxt == String(datePart)
                        }) == false {
                            
                            self.forecastData.append(List(id: i.id, dt: i.dt, main: i.main, weather: i.weather, clouds: i.clouds, wind: i.wind, visibility: i.visibility, pop: i.pop, rain: i.rain, sys: i.sys, dtTxt: String(datePart)))
                        }
                    }
                }
                
            })
            .store(in: &self.cancellables)
    }
    
    //MARK: - Find Hourly Forecast data
    func fetchHourlyWeatherData(lat: Double, lon: Double) {
        
        weatherService.hourlyForecastWeather(lat: lat, lon: lon)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                case .finished:
                    break
                }
                
            }, receiveValue: { [weak self] hourlyResponse in
                DispatchQueue.main.async {
                    self?.hourlyForecastData = hourlyResponse
                }
            })
            .store(in: &self.cancellables)
    }
    
    
    
    
    var inputDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    var outputDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"  // "E" for short weekday, "MMM" for short month
        return formatter
    }
    
    func formattedDate(from string: String) -> String?{
        if let date = inputDateFormatter.date(from: string) {
            return outputDateFormatter.string(from: date)
        }
        return nil
    }
    
    
    func kelvinToCelsius(_ kelvin: Double) -> String {
        let celsius = kelvin - 273.15
        let roundedCelsius = ceil(celsius)
        return String(format: "%.0f", roundedCelsius)
    }
    
    func metersToKilometers(_ meters: Double) -> Double {
        return meters / 1000.0
    }
    
    func calculateDewPoint(temp: Double, humidity: Double) -> Double {
        return temp - ((100 - humidity) / 5)
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // Customize the date format
        formatter.timeStyle = .short // Customize the time format
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM dd, h:mm a"
        return formatter
    }()
    
    func currentDateTime() -> String {
        let now = Date()  // Get the current date and time
        return dateFormatter.string(from: now)
    }
    
    //MARK: - Location
    
    func fetchWeatherForLocation(_ location: CLLocation) {
        let geoURL = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(WeatherService().apiKey)&units=imperial"
        guard let url = URL(string: geoURL) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data"
                }
                return
            }
            do {
                let weather = try JSONDecoder().decode(WeatherResponse.self, from: data)
                DispatchQueue.main.async {
                    self.weatherData = weather
                    self.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        task.resume()
    }
    
    
    
    func searchLocation() {
        guard !cityName.isEmpty else { return }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(cityName) { [weak self] (placemarks, error) in
            if let error = error {
                print("Error geocoding address: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location else {
                print("No location found")
                return
            }
            
            let coordinate = location.coordinate
            DispatchQueue.main.async {
                self?.updateLocation(coordinate: coordinate)
            }
        }
    }
    
    func updateLocation(coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        let annotation = CustomAnnotation(
            coordinate: coordinate,
            title: cityName
        )
        
        annotations = [annotation]
    }
    
    
    //MARK: - Static Hourly Weather Data
    func mockWeatherData() -> [HourlyWeatherData] {
        return [
            HourlyWeatherData(time: "11am", temperature: 22.0, rainIntensity: 0.28, rainProbability: 100, windSpeed: 4.7),
            HourlyWeatherData(time: "12pm", temperature: 22.5, rainIntensity: 0.15, rainProbability: 100, windSpeed: 4.0),
            HourlyWeatherData(time: "1pm", temperature: 23.0, rainIntensity: 0.75, rainProbability: 100, windSpeed: 2.8),
            HourlyWeatherData(time: "2pm", temperature: 23.5, rainIntensity: 0.62, rainProbability: 100, windSpeed: 2.2),
            HourlyWeatherData(time: "3pm", temperature: 24.0, rainIntensity: 0.87, rainProbability: 100, windSpeed: 1.9),
            HourlyWeatherData(time: "4pm", temperature: 24.2, rainIntensity: 0.81, rainProbability: 100, windSpeed: 1.4),
            HourlyWeatherData(time: "5pm", temperature: 24.5, rainIntensity: 0.47, rainProbability: 100, windSpeed: 1.2),
            HourlyWeatherData(time: "6pm", temperature: 24.3, rainIntensity: 0.80, rainProbability: 100, windSpeed: 1.4),
            HourlyWeatherData(time: "7pm", temperature: 24.0, rainIntensity: 0.89, rainProbability: 100, windSpeed: 2.1),
        ]
    }
    
    
}



