//
//  DetailView.swift
//  WeatherApp
//
//  Created by ryan mota on 2025-02-18.
//

import SwiftUI

struct DetailView: View {
    let cityName: String
    @State private var weatherDetail: WeatherDetail?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView("Fetching details...")
            } else if let weather = weatherDetail {
                Image(systemName: getWeatherIcon(for: weather.weather.first?.description ?? ""))
                    .foregroundColor(.blue)
                    .font(.system(size: 60)) // 🌤️ Large icon
                
                Text(weather.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(weather.main.temp, specifier: "%.1f")°C")
                    .font(.system(size: 50))
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text(weather.weather.first?.description.capitalized ?? "Clear")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("Humidity: \(weather.main.humidity)%")
                    .font(.body)
                    .padding()
                
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Weather Details")
        .task {
            await loadWeatherDetail()
        }
    }

    private func loadWeatherDetail() async {
        do {
            weatherDetail = try await WeatherService.shared.fetchWeatherDetail(for: cityName)
            isLoading = false
        } catch {
            print("Error fetching weather details: \(error)")
        }
    }

    private func getWeatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear sky": return "sun.max.fill"
        case "few clouds", "scattered clouds", "broken clouds": return "cloud.sun.fill"
        case "overcast clouds": return "cloud.fill"
        case "shower rain", "rain": return "cloud.rain.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "snow": return "snowflake"
        case "mist", "fog", "haze": return "cloud.fog.fill"
        default: return "questionmark.circle.fill"
        }
    }
}


#Preview {
    DetailView(cityName: "Toronto")
}
