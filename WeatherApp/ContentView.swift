//
//  ContentView.swift
//  WeatherApp
//
//  Created by ryan mota on 2025-02-18.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cities = ["Toronto", "Halifax", "Vancouver", "Edmonton", "St. Catharines", "Niagara Falls"]
    @State private var weatherData: [CityWeather] = []
    @State private var isLoading = false
    @State private var searchText = ""  // 🔍 Holds user input
    @State private var suggestedCities: [CitySuggestion] = []  // 🔽 Suggested cities

    var body: some View {
        NavigationStack {
            VStack {
                // 🔍 Search Bar with Integrated Add Button
                HStack {
                    
                    TextField("Enter a city", text: $searchText)
                        .onChange(of: searchText) { newValue in
                            Task {
                                await updateSuggestions()
                            }
                        }
                    
                    // ➕ Add City Button Inside Search Bar
                    Button(action: {
                        Task {
                            await addCity()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill") // ➕ Add button
                            .foregroundColor(.blue)
                            .font(.system(size: 25))
                    }
                    .padding(.trailing)
                }
                .padding(.top)
                

                // 🔽 Drop-Down Suggestions from API
                if !suggestedCities.isEmpty {
                    List(suggestedCities) { city in
                        Button(action: {
                            searchText = city.displayName // Set selected city
                            suggestedCities = []  // Hide suggestions
                        }) {
                            Text(city.displayName)
                        }
                    }
                    .frame(height: 150) // Limit drop-down height
                }

                // 🌍 Weather List with Swipe-to-Delete
                if isLoading {
                    ProgressView("Fetching Weather...")
                } else {
                    List {
                        ForEach(weatherData) { city in
                            NavigationLink(destination: DetailView(cityName: city.name)) {
                                HStack {
                                    Image(systemName: city.weatherIcon)
                                        .foregroundColor(.blue)
                                        .imageScale(.large)

                                    Text(city.name)
                                        .font(.headline)

                                    Spacer()

                                    Text(city.temperatureString)
                                        .foregroundColor(.blue)
                                }
                                .padding(5)
                            }
                        }
                        .onDelete(perform: removeCity) // 🔥 Swipe-to-Delete
                    }
                    .navigationTitle("Weather App")
                }
            }
        }
        .task {
            await loadWeather()
        }
        .onAppear {
            Task {
                await loadWeather() // 🔄 Refresh on back navigation
            }
        }
    }

    /// ✅ Fetch city suggestions dynamically
    private func updateSuggestions() async {
        guard !searchText.isEmpty else {
            suggestedCities = []
            return
        }

        do {
            let results = try await WeatherService.shared.searchCities(query: searchText)
            DispatchQueue.main.async {
                self.suggestedCities = results
            }
        } catch {
            print("Error fetching city suggestions: \(error)")
        }
    }

    /// ✅ Loads default weather for cities
    private func loadWeather() async {
        isLoading = true
        do {
            weatherData = try await withThrowingTaskGroup(of: CityWeather?.self) { group in
                for city in cities {
                    group.addTask {
                        try? await WeatherService.shared.fetchWeather(for: city)
                    }
                }

                var results: [CityWeather] = []
                for try await result in group {
                    if let weather = result {
                        results.append(weather)
                    }
                }
                return results
            }
            isLoading = false
        } catch {
            print("Error fetching weather: \(error)")
            isLoading = false
        }
    }

    /// ✅ Adds a new city to the list
    private func addCity() async {
        guard !searchText.isEmpty else { return }

        let cityName = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        searchText = ""

        do {
            let newCityWeather = try await WeatherService.shared.fetchWeather(for: cityName)
            if !cities.contains(cityName) {
                cities.append(cityName)  // ✅ Add to list only if it’s not a duplicate
            }
            weatherData.append(newCityWeather) // ✅ Add new weather entry
        } catch {
            print("Error fetching weather for \(cityName): \(error)")
        }
    }

    /// ✅ Removes a city from the list
    private func removeCity(at offsets: IndexSet) {
        for index in offsets {
            let cityToRemove = weatherData[index].name
            cities.removeAll { $0 == cityToRemove }
        }
        weatherData.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
