//
//  WeatherView.swift
//  WeatherApp
//
//  Created by Venuka Valiveti on 13/09/24.

import SwiftUI
import CoreLocation
import MapKit
import DGCharts
import Charts

struct WeatherView: View {
    @StateObject var viewModel = WeatherViewModel()
    @State private var locationManager = LocationManager()
    @State private var useLocationWeather: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack{
                ScrollView{
                    VStack{
                        Image("garden")
                            .resizable()
                            .frame(height: 150)
                            .overlay {
                                VStack(alignment: .leading,spacing: 10){
                                    Text("OpenWeather")
                                        .padding()
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    Text("Weather forecasts, nowcasts and \n history in a fast and elegant way")
                                        .multilineTextAlignment(.center)
                                        .padding()
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                            }
                            .edgesIgnoringSafeArea(.top)
                        
                        HStack {
                            TextField("Search City", text:$viewModel.cityName,onCommit: {
                                viewModel.fetchWeather(for: viewModel.cityName)
                                viewModel.searchLocation()
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .overlay {
                                HStack{
                                    Spacer()
                                    Button(action: {
                                        if !viewModel.cityName.isEmpty {
                                            viewModel.fetchWeather(for: viewModel.cityName)
                                            useLocationWeather = false
                                            viewModel.searchLocation()
                                        }
                                        
                                    }, label: {
                                        Text("Search")
                                            .foregroundStyle(.white)
                                    })
                                    .frame(width: 80, height: 30)
                                    .background(.black)
                                    .padding()
                                }
                            }
                        }
                        
                        Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.annotations) { annotation in
                            MapPin(coordinate: annotation.coordinate, tint: .blue)
                        }
                        .frame(height: 200)
                        .edgesIgnoringSafeArea([.leading,.trailing])
                        
                        
                        if let weather = viewModel.weatherData {
                            HStack{
                                
                                VStack(alignment: .leading, spacing: 0){
                                    Text(viewModel.currentDateTime())
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                    Text("\(weather.name), \(weather.sys.country)")
                                        .font(SwiftUI.Font.system(size: 20, weight: .semibold))
                                    HStack(spacing: 0){
                                        
                                        if let icon = weather.weather.first?.icon {
                                            AsyncImage(url: iconUrl(icon: icon)) { image in
                                                image.resizable()
                                                    .scaledToFit()
                                                    .frame(width: 50, height: 50)
                                            } placeholder: {
                                                ProgressView()
                                            }
                                        }
                                        
                                        Text("\(viewModel.kelvinToCelsius(weather.main.temp))°C")
                                            .font(SwiftUI.Font.system(size: 20, weight: .semibold))
                                        
                                    }
                                    HStack(spacing: 8){
                                        Text("Feels like \(viewModel.kelvinToCelsius(weather.main.feelsLike))°C")
                                            .font(.system(size: 17, weight: .semibold))
                                        Text("\(weather.weather.first?.main ?? "").")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    
                                    HStack(spacing:20){
                                        VStack(alignment: .leading,spacing: 5){
                                            Text("\(String(format: "%.1f",weather.wind.speed))m/s")
                                                .font(.subheadline)
                                            Text("Humidity: \(weather.main.humidity)%")
                                                .font(.subheadline)
                                        }
                                        VStack(alignment: .leading,spacing: 5){
                                            Text("\(String(weather.main.pressure))hPa")
                                                .font(.subheadline)
                                            Text("Dew Point: \(viewModel.calculateDewPoint(temp: Double(viewModel.kelvinToCelsius(weather.main.feelsLike)) ?? 0.0, humidity: Double(weather.main.humidity)), specifier: "%.1f") °C")
                                                .font(.subheadline)
                                        }
                                    }
                                    .padding(.top,5)
                                    HStack{
                                        Text("Visibility: \(viewModel.metersToKilometers(Double(weather.visibility)),specifier: "%.1f")Km")
                                            .font(.subheadline)
                                    }
                                    .padding(.top,5)
                                    
                                }.padding(.leading, 20)
                                Spacer()
                            }
                        }else if let errorMessage = viewModel.errorMessage {
                            Text("Error: \(errorMessage)")
                        }
                        
                        
                        // 8-Day Forecast
                        DayForecastView(viewModel: viewModel)
                        
                        //Hourly Chart report
                        WeatherChartView(weatherData: viewModel.mockWeatherData())
                            .frame(height: 300)
                            .padding()
                    }
                }
            }
            .onAppear {
                if let lastCity = UserDefaults.standard.string(forKey: "lastCity") {
                    viewModel.cityName = lastCity
                    viewModel.fetchWeather(for: lastCity)
                } else if useLocationWeather {
                    locationManager.requestLocation()
                }
            }
            .onChange(of: locationManager.location) { newLocation in
                if useLocationWeather, let location = newLocation {
                    viewModel.fetchWeatherForLocation(location)
                }
            }
            .navigationTitle("Weather App")
        }
    }
    
}

func iconUrl(icon: String) -> URL? {
    //return URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")
    return URL(string:"https://openweathermap.org/img/wn/\(icon).png")
}

//MARK: - 8 Day Forecast View

struct DayForecastView:View{
    @StateObject var viewModel:WeatherViewModel
    @State private var selectedForecast: UUID? = nil
    var body: some View{
        VStack {
            Text("8-Day Forecast")
                .font(.system(size: 22, weight: .semibold))
                .padding()
            
            ForEach(viewModel.forecastData,id:\.id) { obj in
                VStack{
                    if viewModel.isExpand{
                        if selectedForecast == obj.id {
                            VStack{
                                HStack{
                                    // Horizontal ScrollView to replace the row
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(viewModel.forecastData,id:\.id){ listObj in
                                                VStack {
                                                    Button {
                                                        selectedForecast = listObj.id//forecast.id
                                                    } label: {
                                                        Text("\(viewModel.formattedDate(from:listObj.dtTxt) ?? "")")
                                                            .font(.headline)
                                                            .foregroundColor(.black)
                                                    }
                                                    
                                                }
                                                .padding()
                                            }
                                        }
                                    }
                                    .transition(.slide) // Slide in animation
                                    Button {
                                        viewModel.isExpand.toggle()
                                    } label: {
                                        Image(systemName:"arrowtriangle.up.fill")
                                            .resizable()
                                            .foregroundColor(.black)
                                            .frame(width: 12, height:10, alignment: .center)
                                            .padding(.trailing,10)
                                    }
                                    
                                }
                                .frame(height: 50) // Adjust height as needed
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                if selectedForecast == obj.id{
                                    HStack{
                                        if let icon = obj.weather.first?.icon {
                                            AsyncImage(url: iconUrl(icon: icon)) { image in
                                                image.resizable()
                                                    .scaledToFit()
                                                    .frame(width: 40, height: 40)
                                            } placeholder: {
                                                ProgressView()
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 10){
                                            Text(obj.weather.first?.description ?? "")
                                                .font(.headline)
                                            Text("The high will be \(viewModel.kelvinToCelsius(obj.main.tempMax))°C, the low will be \(viewModel.kelvinToCelsius(obj.main.tempMin))°C")
                                        }
                                    }
                                    
                                    HStack(spacing:20){
                                        VStack(alignment: .leading,spacing: 5){
                                            Text("\(String(format: "%.1f",obj.wind.speed))m/s")
                                                .font(.subheadline)
                                            Text("Humidity: \(obj.main.humidity)%")
                                                .font(.subheadline)
                                        }
                                        VStack(alignment: .leading,spacing: 5){
                                            Text("\(String(obj.main.pressure))hPa")
                                                .font(.subheadline)
                                            Text("Dew Point: \(viewModel.calculateDewPoint(temp: Double(viewModel.kelvinToCelsius(obj.main.feelsLike)) ?? 0.0, humidity: Double(obj.main.humidity)), specifier: "%.1f") °C")
                                                .font(.subheadline)
                                        }
                                    }
                                    .padding(.top,5)
                                }
                            }
                        }
                    } else {
                        HStack{
                            VStack(alignment: .leading) {
                                HStack{
                                    Text("\(viewModel.formattedDate(from:obj.dtTxt) ?? "")")
                                        .font(.headline)
                                        .padding(.trailing,10)
                                    HStack{
                                        if let icon = obj.weather.first?.icon {
                                            AsyncImage(url: iconUrl(icon: icon)) { image in
                                                image.resizable()
                                                    .scaledToFit()
                                                    .frame(width: 40, height: 40)
                                            } placeholder: {
                                                ProgressView()
                                            }
                                        }
                                        
                                        Text("\(viewModel.kelvinToCelsius(obj.main.tempMax))/\(viewModel.kelvinToCelsius(obj.main.tempMin)) °C")
                                            .font(.body)
                                    }
                                }
                            }
                            Spacer()
                            //Weather Condition
                            VStack(alignment: .trailing){
                                HStack{
                                    Text(obj.weather.first?.description ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Image(systemName:"arrowtriangle.down.fill")
                                        .resizable()
                                        .foregroundColor(.black)
                                        .frame(width: 12, height:10, alignment: .center)
                                    
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .animation(.default, value: selectedForecast)
                        .contentShape(Rectangle())  // Makes the whole row tappable
                        .onTapGesture {
                            viewModel.isExpand.toggle()
                            selectedForecast = obj.id
                        }
                    }
                }
                .padding([.leading,.trailing],10)
                
            }
        }
        .padding(.bottom,20)
    }
}


//MARK: -  Hourly Weather Report Graph View

struct WeatherChartView: UIViewRepresentable {
    var weatherData: [HourlyWeatherData]
    
    func makeUIView(context: Context) -> CombinedChartView {
        let chartView = CombinedChartView()
        chartView.delegate = context.coordinator
        
        // Configure chart axes
        chartView.rightAxis.enabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: weatherData.map { $0.time })
        chartView.leftAxis.axisMinimum = 0
        
        return chartView
    }
    
    func updateUIView(_ uiView: CombinedChartView, context: Context) {
        let temperatureEntries = weatherData.enumerated().map { (index, data) -> ChartDataEntry in
            return ChartDataEntry(x: Double(index), y: data.temperature)
        }
        
        let rainEntries = weatherData.enumerated().map { (index, data) -> BarChartDataEntry in
            return BarChartDataEntry(x: Double(index), y: data.rainIntensity)
        }
        
        // Set up LineChartDataSet for temperature
        let temperatureDataSet = LineChartDataSet(entries: temperatureEntries, label: "Temperature (°C)")
        temperatureDataSet.colors = [UIColor.systemRed]
        temperatureDataSet.valueColors = [UIColor.systemRed]
        temperatureDataSet.circleColors = [UIColor.systemRed]
        temperatureDataSet.circleRadius = 4
        temperatureDataSet.mode = .cubicBezier // Smooth line
        
        // Set up BarChartDataSet for rain intensity
        let rainDataSet = BarChartDataSet(entries: rainEntries, label: "Rain Intensity (mm/h)")
        rainDataSet.colors = [UIColor.systemTeal]
        rainDataSet.valueColors = [UIColor.systemTeal]
        
        // Combine the two datasets
        let combinedData = CombinedChartData()
        combinedData.barData = BarChartData(dataSet: rainDataSet)
        combinedData.lineData = LineChartData(dataSet: temperatureDataSet)
        
        uiView.data = combinedData
        
        // Refresh the chart view
        uiView.notifyDataSetChanged()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ChartViewDelegate {
        var parent: WeatherChartView
        
        init(_ parent: WeatherChartView) {
            self.parent = parent
        }
    }
}

