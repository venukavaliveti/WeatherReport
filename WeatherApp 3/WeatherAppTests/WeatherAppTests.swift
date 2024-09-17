//
//  WeatherAppTests.swift
//  WeatherAppTests
//
//  Created by Venuka Valiveti on 13/09/24.
//

import XCTest
import Combine
@testable import WeatherApp

class WeatherAppTests: XCTestCase {

    var viewModel: WeatherViewModel!
        var mockService: MockWeatherService!
        var cancellables = Set<AnyCancellable>()
        
        override func setUp() {
            mockService = MockWeatherService()
            viewModel = WeatherViewModel(weatherService: mockService)
        }
        
        override func tearDown() {
            viewModel = nil
            mockService = nil
            cancellables.removeAll()
        }
    func testFetchWeatherSuccess() {
        let expectation = self.expectation(description: "Fetch weather")
        
        viewModel.fetchWeather(for: "Plano")
        
        viewModel.$weatherData
            .dropFirst()
            .sink { weather in
                XCTAssertEqual(weather?.name, "Plano")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 2, handler: nil)
        }
    func testFetchWeatherFailure() {
        mockService.shouldFail = true
        let expectation = self.expectation(description: "Fetch weather failure")
        
        viewModel.fetchWeather(for: "Invalid City")
        
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertEqual(errorMessage, "Invalid city name. Please try again.")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 2, handler: nil)
        }
    
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}


// Mock Service
// Mock Service
class MockWeatherService: WeatherServiceProtocol {
    func hourlyForecastWeather(lat: Double, lon: Double) -> AnyPublisher<WeatherApp.HourlyWeatherForecast, WeatherApp.WeatherError> {
        return Fail(error: WeatherError.invalidCity)
             .eraseToAnyPublisher()
    }
    
    func fetchForecast(lat: Double, lon: Double) -> AnyPublisher<WeatherForecast, WeatherError> {
        return Fail(error: WeatherError.invalidCity)
            .eraseToAnyPublisher()
    }
    
    var shouldFail = false

    func fetchWeather(for city: String) -> AnyPublisher<WeatherResponse, WeatherError> {
        if shouldFail {
            return Fail(error: WeatherError.invalidCity)
                .eraseToAnyPublisher()
        } else {
            
            let mockWeather = WeatherResponse(coord:Coord(lon: -96.6989, lat: 33.0198) , weather: [Weather(id:0, main: "",description: "clear sky", icon: "01n")], base: "", main: Main(temp: 0.0, feelsLike: 0.0, tempMin: 0.0, tempMax: 0.0, pressure: 0, humidity: 0, seaLevel: 0, grndLevel: 0), visibility: 0, wind: Wind(speed: 0.0, deg: 0, gust: 0.0), clouds: Clouds(all: 0), dt: 0, sys: Sys(type: 0, id: 0, country: "", sunrise: 0, sunset: 0), timezone: 0, id: 0, name: "Plano", cod: 0)
            return Just(mockWeather)
                .setFailureType(to: WeatherError.self)
                .eraseToAnyPublisher()
        }
    }
}
