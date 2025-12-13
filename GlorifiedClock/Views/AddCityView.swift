
//
//  AddCityView.swift
//  GlorifiedClock
//

import SwiftUI

// MARK: - Add City View

struct AddCityView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TimeViewModel
    @State private var searchText: String = ""
    
    struct CitySuggestion: Identifiable {
        let id = UUID()
        let name: String
        let timeZoneID: String
    }
    
    private let featuredCities: [CitySuggestion] = [
        CitySuggestion(name: "Tamil Nadu (Chennai)", timeZoneID: "Asia/Kolkata"),
        CitySuggestion(name: "Bangalore", timeZoneID: "Asia/Kolkata"),
        CitySuggestion(name: "Dubai", timeZoneID: "Asia/Dubai"),
        CitySuggestion(name: "Cupertino", timeZoneID: "America/Los_Angeles"),
        CitySuggestion(name: "New York", timeZoneID: "America/New_York"),
        CitySuggestion(name: "Paris", timeZoneID: "Europe/Paris"),
        CitySuggestion(name: "Singapore", timeZoneID: "Asia/Singapore"),
        CitySuggestion(name: "Sydney", timeZoneID: "Australia/Sydney"),
    ]
    
    private var filteredFeatured: [CitySuggestion] {
        searchText.isEmpty ? featuredCities : featuredCities.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredTimeZones: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers
        return searchText.isEmpty ? all : all.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !filteredFeatured.isEmpty {
                    Section("Popular Cities") {
                        ForEach(filteredFeatured) { suggestion in
                            Button {
                                if let tz = TimeZone(identifier: suggestion.timeZoneID) {
                                    viewModel.addCity(named: suggestion.name, timeZone: tz)
                                }
                                dismiss()
                            } label: {
                                HStack {
                                    Text(suggestion.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("All Time Zones") {
                    ForEach(filteredTimeZones, id: \.self) { identifier in
                        Button {
                            if let tz = TimeZone(identifier: identifier) {
                                viewModel.addCity(named: identifier, timeZone: tz)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Text(identifier)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add City")
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}
