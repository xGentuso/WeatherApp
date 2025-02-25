//
//  WeatherWidget.swift
//  WeatherWidget
//
//  Created by ryan mota on 2025-02-20.
//

import WidgetKit
import SwiftUI

struct WeatherEntry: TimelineEntry {
    let date: Date
    let cityWeather: CityWeather?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), cityWeather: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        Task {
            let entry = await fetchWeatherEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        Task {
            let entry = await fetchWeatherEntry()
            let nextUpdate = Date().addingTimeInterval(30) // Refresh every hour
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    /// Fetches weather data using the stored location from UserDefaults (App Group).
    private func fetchWeatherEntry() async -> WeatherEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.triosRM.WeatherApp")

        if let locationArray = sharedDefaults?.array(forKey: "lastLocation") as? [Double], locationArray.count == 2 {
            let latitude = locationArray[0]
            let longitude = locationArray[1]

            print("📍 Widget retrieved location: \(latitude), \(longitude)")

            do {
                let roundedLat = Double(String(format: "%.4f", latitude)) ?? latitude
                let roundedLon = Double(String(format: "%.4f", longitude)) ?? longitude
                let weather = try await WeatherService.shared.fetchWeather(for: "\(roundedLat),\(roundedLon)")
                
                return WeatherEntry(date: Date(), cityWeather: weather)
            } catch {
                print("❌ Error fetching weather: \(error)")
                return WeatherEntry(date: Date(), cityWeather: nil)
            }
        } else {
            print("❌ No location data found in UserDefaults")
            return WeatherEntry(date: Date(), cityWeather: nil)
        }
    }
}

struct WeatherWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            if let weather = entry.cityWeather {
                Image(systemName: weather.weatherIcon)
                    .font(.largeTitle)
                
                Text(weather.name)
                    .font(.headline)
                
                Text(weather.temperatureString)
                    .font(.title)
            } else {
                Text("Location not available")
                    .font(.footnote)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Local Weather")
        .description("Shows current weather for your location.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
