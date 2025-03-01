//
//  Item.swift
//  WeatherApp
//
//  Created by ryan mota on 2025-02-18.
//

import Foundation

struct CityWeather: Identifiable, Codable {
    var id = UUID()
    let name: String
    let temperature: Double
    let condition: String
    
    var temperatureString: String {
        String(format: "%.1f°C", temperature)
    }
    
    var weatherIcon: String {
        switch condition.lowercased() {
        case "clear sky": return "sun.max.fill"
        case "few clouds", "scattered clouds", "broken clouds": return "cloud.sun.fill"
        case "overcast clouds": return "cloud.fill"
        case "moderate rain", "rain": return "cloud.rain.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "snow": return "snowflake"
        case "mist", "fog", "haze": return "cloud.fog.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

struct WeatherDetail: Codable {
    let name: String
    let main: Main
    let weather: [Weather]

    struct Main: Codable {
        let temp: Double
        let humidity: Int
    }

    struct Weather: Codable {
        let description: String
    }
}

// MARK: - Forecast Models (moved to top level for clarity)

struct ForecastResponse: Codable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable {
    let dt: TimeInterval
    let main: ForecastMain
    let weather: [ForecastWeather]
}

struct ForecastMain: Codable {
    let temp: Double
}

struct ForecastWeather: Codable {
    let description: String
}

// A model to represent daily (aggregated) forecast data
struct DailyForecast: Identifiable {
    var id = UUID()
    let date: Date
    let averageTemp: Double
    let condition: String
    
    var temperatureString: String {
        String(format: "%.1f°C", averageTemp)
    }
    
    var weatherIcon: String {
        switch condition.lowercased() {
        case "clear sky": return "sun.max.fill"
        case "few clouds", "scattered clouds", "broken clouds": return "cloud.sun.fill"
        case "overcast clouds": return "cloud.fill"
        case "moderate rain", "rain": return "cloud.rain.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "snow": return "snowflake"
        case "mist", "fog", "haze": return "cloud.fog.fill"
        default: return "questionmark.circle.fill"
        }
    }
    var dayOfWeek: String {
          let formatter = DateFormatter()
          formatter.dateFormat = "EEEE" // "Monday", "Tuesday", etc.
          return formatter.string(from: date)
      }
}
