//
//  APIService.swift
//  WeatherApp
//
//  Created by ryan mota on 2025-02-18.
//

import Foundation

struct CitySuggestion: Identifiable, Codable {
    var id = UUID()
    let name: String
    let country: String
    
    var displayName: String {
        "\(name), \(country)" // E.g., "Victoria, CA"
    }
}

class WeatherService {
    static let shared = WeatherService()
    private let apiKey = "f54761d651d7cf750ff91c6442e2c20e"
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let geoBaseURL = "https://api.openweathermap.org/geo/1.0/direct"
    
    /// Fetch weather details for a given city name or coordinates.
    /// If the input string is in the format "lat,lon", the method uses latitude and longitude parameters.
    func fetchWeather(for cityOrCoordinates: String) async throws -> CityWeather {
        let urlString: String
        // Attempt to detect a coordinate string by splitting on ","
        let components = cityOrCoordinates.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if components.count == 2,
           let lat = Double(components[0]),
           let lon = Double(components[1]) {
            // Use lat/lon parameters when coordinates are provided
            urlString = "\(baseURL)?lat=\(lat)&lon=\(lon)&units=metric&appid=\(apiKey)"
        } else {
            // Otherwise assume it's a city name and encode it properly
            let encodedCity = cityOrCoordinates.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cityOrCoordinates
            urlString = "\(baseURL)?q=\(encodedCity)&units=metric&appid=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedData = try JSONDecoder().decode(WeatherDetail.self, from: data)
        let condition = decodedData.weather.first?.description ?? "Unknown"
        
        return CityWeather(name: decodedData.name,
                           temperature: decodedData.main.temp,
                           condition: condition)
    }
    
    /// Fetch detailed weather information for a given city name or coordinates.
    func fetchWeatherDetail(for cityOrCoordinates: String) async throws -> WeatherDetail {
        let urlString: String
        let components = cityOrCoordinates.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if components.count == 2,
           let lat = Double(components[0]),
           let lon = Double(components[1]) {
            urlString = "\(baseURL)?lat=\(lat)&lon=\(lon)&units=metric&appid=\(apiKey)"
        } else {
            let encodedCity = cityOrCoordinates.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cityOrCoordinates
            urlString = "\(baseURL)?q=\(encodedCity)&units=metric&appid=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WeatherDetail.self, from: data)
    }
    
    /// Fetch matching cities dynamically using the OpenWeatherMap Geo API.
    func searchCities(query: String) async throws -> [CitySuggestion] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(geoBaseURL)?q=\(encodedQuery)&limit=5&appid=\(apiKey)"
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedData = try JSONDecoder().decode([GeoCity].self, from: data)
        return decodedData.map { CitySuggestion(name: $0.name, country: $0.country) }
    }
    
    /// Fetch 5-day (3-hour interval) forecast for a given city, aggregate the data by day, and return daily summaries.
    func fetchForecast(for city: String) async throws -> [DailyForecast] {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let forecastURLString = "https://api.openweathermap.org/data/2.5/forecast?q=\(encodedCity)&units=metric&appid=\(apiKey)"
        guard let url = URL(string: forecastURLString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let forecastResponse = try JSONDecoder().decode(ForecastResponse.self, from: data)
        
        // Group forecast items by day (using "yyyy-MM-dd" format)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Group forecast items by the start of each day
        let grouped = Dictionary(grouping: forecastResponse.list) { item -> Date in
            // Convert the timestamp to a Date and round down to midnight
            let date = Date(timeIntervalSince1970: item.dt)
            return Calendar.current.startOfDay(for: date)
        }
        
        // Create a DailyForecast for each group
        let dailyForecasts: [DailyForecast] = grouped.map { (dayDate, items) in
            let avgTemp = items.map { $0.main.temp }.reduce(0, +) / Double(items.count)
            let condition = items.first?.weather.first?.description ?? "Unknown"
            return DailyForecast(date: dayDate, averageTemp: avgTemp, condition: condition)
        }
        
        // Sort the results by ascending date
        return dailyForecasts.sorted { $0.date < $1.date }
    }
}

/// Struct to parse OpenWeatherMap's geo response.
struct GeoCity: Codable {
    let name: String
    let country: String
}
