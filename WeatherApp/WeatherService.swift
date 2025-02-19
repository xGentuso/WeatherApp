//
//  APIService.swift
//  WeatherApp
//
//  Created by ryan mota on 2025-02-18.
//

import Foundation

struct CitySuggestion: Identifiable, Codable {
    let id = UUID()
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

    /// ✅ Fetch weather details for a given city
    func fetchWeather(for city: String) async throws -> CityWeather {
        let urlString = "\(baseURL)?q=\(city)&units=metric&appid=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedData = try JSONDecoder().decode(WeatherDetail.self, from: data)
        let condition = decodedData.weather.first?.description ?? "Unknown"
        
        return CityWeather(name: decodedData.name, temperature: decodedData.main.temp, condition: condition)
    }
    

    /// ✅ Fetch detailed weather info
    func fetchWeatherDetail(for city: String) async throws -> WeatherDetail {
        let urlString = "\(baseURL)?q=\(city)&units=metric&appid=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WeatherDetail.self, from: data)
    }

    /// ✅ Fetch matching cities dynamically (with country codes)
    func searchCities(query: String) async throws -> [CitySuggestion] {
        let urlString = "\(geoBaseURL)?q=\(query)&limit=5&appid=\(apiKey)"
        guard let url = URL(string: urlString) else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedData = try JSONDecoder().decode([GeoCity].self, from: data)

        return decodedData.map { CitySuggestion(name: $0.name, country: $0.country) }
    }
}

/// ✅ Struct to parse OpenWeatherMap's geo response
struct GeoCity: Codable {
    let name: String
    let country: String
}
