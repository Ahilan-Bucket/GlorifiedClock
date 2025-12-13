
//
//  TimeViewModel.swift
//  GlorifiedClock
//

import SwiftUI
import UIKit

// MARK: - View Model

@MainActor
class TimeViewModel: ObservableObject {
    @Published var cities: [CityTime] = []
    @Published var use24HourFormat: Bool = false
    @Published var showRipple: Bool = false
    @Published var showingAddCity: Bool = false
    @Published var currentTime: Date = Date()
    
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    private var timer: Timer?
    
    let hours = Array(0...23)
    
    init() {
        hapticGenerator.prepare()
        
        let vancouver = CityTime(
            name: "Vancouver",
            timeZone: TimeZone(identifier: "America/Vancouver") ?? .current,
            isHome: true
        )
        
        let london = CityTime(
            name: "London",
            timeZone: TimeZone(identifier: "Europe/London") ?? .current,
            isHome: false
        )
        
        let tokyo = CityTime(
            name: "Tokyo",
            timeZone: TimeZone(identifier: "Asia/Tokyo") ?? .current,
            isHome: false
        )
        
        self.cities = [vancouver, london, tokyo]
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentTime = Date()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    var homeCity: CityTime? {
        cities.first
    }
    
    func timezoneAbbreviation(for city: CityTime) -> String {
        city.timeZone.abbreviation(for: currentTime) ?? ""
    }
    
    func currentDateString(for city: CityTime) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: currentTime)
    }
    
    func currentTimeString(for city: CityTime) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.dateFormat = use24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: currentTime)
    }
    
    func isDifferentDay(city: CityTime, from home: CityTime) -> Bool {
        var homeCalendar = Calendar.current
        homeCalendar.timeZone = home.timeZone
        
        var cityCalendar = Calendar.current
        cityCalendar.timeZone = city.timeZone
        
        let homeDay = homeCalendar.component(.day, from: currentTime)
        let cityDay = cityCalendar.component(.day, from: currentTime)
        
        return homeDay != cityDay
    }
    
    func baseDate(for hour: Int) -> Date {
        guard let home = homeCity else { return Date() }
        
        var calendar = Calendar.current
        calendar.timeZone = home.timeZone
        
        return calendar.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: currentTime
        ) ?? currentTime
    }
    
    func formattedTime(_ date: Date, for city: CityTime) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.dateFormat = use24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
    
    func addCity(named name: String, timeZone: TimeZone) {
        if cities.contains(where: { $0.name == name && $0.timeZone == timeZone }) {
            return
        }
        let newCity = CityTime(name: name, timeZone: timeZone, isHome: false)
        cities.append(newCity)
    }
    
    func removeCity(_ city: CityTime) {
        guard let first = cities.first, first.id != city.id else { return }
        cities.removeAll { $0.id == city.id }
    }
    
    func setHome(_ city: CityTime) {
        guard let tappedIndex = cities.firstIndex(where: { $0.id == city.id }) else { return }
        if tappedIndex == 0 { return }
        
        triggerRipple()
        triggerHaptic()
        
        var updated = cities
        updated.swapAt(0, tappedIndex)
        
        for idx in updated.indices {
            updated[idx].isHome = (idx == 0)
        }
        
        cities = updated
    }
    
    func currentHourInHome() -> Int {
        guard let home = homeCity else { return 0 }
        var calendar = Calendar.current
        calendar.timeZone = home.timeZone
        return calendar.component(.hour, from: currentTime)
    }
    
    func triggerHaptic() {
        hapticGenerator.impactOccurred(intensity: 0.5)
    }
    
    func triggerRipple() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            showRipple = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.showRipple = false
        }
    }
}
