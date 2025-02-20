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
    let city: String
    let temperature: String
    let condition: String
    let weatherIcon: String
}

struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), city: "Toronto", temperature: "10°C", condition: "Clear", weatherIcon: "sun.max.fill")
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        let entry = WeatherEntry(date: Date(), city: "Toronto", temperature: "10°C", condition: "Clear", weatherIcon: "sun.max.fill")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        Task {
            let city = "Toronto" // Default city (you can modify this)
            
            do {
                let weather = try await WeatherService.shared.fetchWeather(for: city)
                let entry = WeatherEntry(
                    date: Date(),
                    city: weather.name,
                    temperature: weather.temperatureString,
                    condition: weather.condition,
                    weatherIcon: weather.weatherIcon
                )

                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                print("Error fetching weather for widget: \(error)")
                let fallbackEntry = WeatherEntry(date: Date(), city: "Unknown", temperature: "--°C", condition: "Unknown", weatherIcon: "questionmark.circle.fill")
                let timeline = Timeline(entries: [fallbackEntry], policy: .after(Date().addingTimeInterval(1800))) // Retry in 30 min
                completion(timeline)
            }
        }
    }
}

struct WeatherWidgetView: View {
    var entry: WeatherProvider.Entry

    var body: some View {
        VStack {
            Text(entry.city)
                .font(.headline)

            Image(systemName: entry.weatherIcon)
                .font(.largeTitle)
                .foregroundColor(.blue)

            Text(entry.temperature)
                .font(.title)
                .bold()

            Text(entry.condition)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            WeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("Weather Widget")
        .description("Shows the current weather for a city.")
        .supportedFamilies([.systemSmall, .systemMedium]) // Widget sizes
    }
}
