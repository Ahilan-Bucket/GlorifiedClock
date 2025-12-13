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
    @Published var currentTime: Date = Date()  // Live clock time
    @Published var selectedDate: Date = Date()  // Date being viewed in grid
    @Published var events: [TimeEvent] = []
    
    // Event creation state
    @Published var isCreatingEvent: Bool = false
    @Published var eventStartHour: Int?
    @Published var eventEndHour: Int?
    @Published var selectedCity: CityTime?
    @Published var showingEventEditor: Bool = false
    @Published var eventBeingEdited: TimeEvent?
    
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
    
    // MARK: - Date/Time Checks
    
    func isViewingToday() -> Bool {
        guard let home = homeCity else { return false }
        var calendar = Calendar.current
        calendar.timeZone = home.timeZone
        return calendar.isDate(selectedDate, inSameDayAs: currentTime)
    }
    
    // MARK: - Formatters (Live Time - for headers)
    
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
    
    // MARK: - Formatters (Viewed Date - for grid)
    
    func viewedDateString(for city: CityTime) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: selectedDate)
    }
    
    func isDifferentDay(city: CityTime, from home: CityTime) -> Bool {
        var homeCalendar = Calendar.current
        homeCalendar.timeZone = home.timeZone
        
        var cityCalendar = Calendar.current
        cityCalendar.timeZone = city.timeZone
        
        // Use selectedDate instead of currentTime
        let homeDay = homeCalendar.component(.day, from: selectedDate)
        let cityDay = cityCalendar.component(.day, from: selectedDate)
        
        return homeDay != cityDay
    }
    
    func formattedTime(_ date: Date, for city: CityTime) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.dateFormat = use24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
    
    // MARK: - City Management
    
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
    
    // MARK: - Haptics
    
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
    
    // MARK: - Day Boundary Detection
    
    func isMidnightBoundary(_ hour: Int, for city: CityTime) -> Bool {
        guard hour > 0 else { return false }  // First hour can't have boundary before it
        
        let currentHourBase = baseDate(for: hour, in: city)
        let previousHourBase = baseDate(for: hour - 1, in: city)
        
        var calendar = Calendar.current
        calendar.timeZone = city.timeZone
        
        let currentDay = calendar.component(.day, from: currentHourBase)
        let previousDay = calendar.component(.day, from: previousHourBase)
        
        return currentDay != previousDay  // Day changed = midnight crossed
    }
    
    func dateStringAtHour(_ hour: Int, for city: CityTime) -> String {
        let base = baseDate(for: hour, in: city)
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: base)
    }
    
    // MARK: - Timeline Calculation
    
    func baseDate(for hour: Int, in city: CityTime) -> Date {
        let anchor = timelineAnchorDate()
        
        var calendar = Calendar.current
        calendar.timeZone = city.timeZone
        
        return calendar.date(byAdding: .hour, value: hour, to: anchor) ?? anchor
    }
    
    func baseDate(for hour: Int) -> Date {
        guard let home = homeCity else { return Date() }
        return baseDate(for: hour, in: home)
    }
    
    func timelineAnchorDate() -> Date {
        guard let home = homeCity else { return selectedDate }
        
        var calendar = Calendar.current
        calendar.timeZone = home.timeZone
        return calendar.startOfDay(for: selectedDate)  // Uses selectedDate
    }
    
    // MARK: - Day Relationship
    
    func dayRelationship(city: CityTime, atHour hour: Int) -> DayRelationship {
        guard let home = homeCity else { return .same }
        
        let cityDate = baseDate(for: hour, in: city)
        let homeDate = baseDate(for: hour, in: home)
        
        var cityCalendar = Calendar.current
        cityCalendar.timeZone = city.timeZone
        
        var homeCalendar = Calendar.current
        homeCalendar.timeZone = home.timeZone
        
        let cityDay = cityCalendar.startOfDay(for: cityDate)
        let homeDay = homeCalendar.startOfDay(for: homeDate)
        
        if cityDay > homeDay {
            return .next
        } else if cityDay < homeDay {
            return .previous
        } else {
            return .same
        }
    }
    
    // MARK: - Date Navigation
    
    func goToToday() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedDate = Date()
        }
    }
    
    func selectDate(_ date: Date) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedDate = date
        }
    }
    
    func goToNextDay() {
        guard let home = homeCity else { return }
        var calendar = Calendar.current
        calendar.timeZone = home.timeZone
        
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = nextDay
            }
            triggerHaptic()
        }
    }
    
    func goToPreviousDay() {
        guard let home = homeCity else { return }
        var calendar = Calendar.current
        calendar.timeZone = home.timeZone
        
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = previousDay
            }
            triggerHaptic()
        }
    }
    
    // MARK: - Event Management
    
    func startEventCreation(city: CityTime, hour: Int) {
        selectedCity = city
        eventStartHour = hour
        eventEndHour = hour
        isCreatingEvent = true
        triggerHaptic()
    }
    
    func updateEventEnd(hour: Int) {
        guard isCreatingEvent, let start = eventStartHour else { return }
        // Ensure end is after start
        eventEndHour = max(start, hour)
    }
    
    func cancelEventCreation() {
        isCreatingEvent = false
        eventStartHour = nil
        eventEndHour = nil
        selectedCity = nil
    }
    
    func finalizeEventCreation() {
        guard let city = selectedCity,
              let startHour = eventStartHour,
              let endHour = eventEndHour else {
            cancelEventCreation()
            return
        }
        
        let startDate = baseDate(for: startHour, in: city)
        let endDate = baseDate(for: endHour + 1, in: city)
        
        let newEvent = TimeEvent(
            title: "New Event",
            startDate: startDate,
            endDate: endDate,
            cityTimeZone: city.timeZone
        )
        
        eventBeingEdited = newEvent
        showingEventEditor = true
        
        // Reset creation state
        isCreatingEvent = false
        eventStartHour = nil
        eventEndHour = nil
        selectedCity = nil
        
        triggerHaptic()
    }
    
    func saveEvent(_ event: TimeEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
    }
    
    func deleteEvent(_ event: TimeEvent) {
        events.removeAll { $0.id == event.id }
    }
    
    func eventsForHour(_ hour: Int, in city: CityTime) -> [TimeEvent] {
        let hourStart = baseDate(for: hour, in: city)
        let hourEnd = baseDate(for: hour + 1, in: city)
        
        return events.filter { event in
            event.cityTimeZone == city.timeZone &&
            event.startDate < hourEnd &&
            event.endDate > hourStart
        }
    }
    
    func exportEventsToICS() -> String {
        return events.toICSFile()
    }
    
    func isHourInEventSelection(hour: Int) -> Bool {
        guard isCreatingEvent,
              let start = eventStartHour,
              let end = eventEndHour else {
            return false
        }
        return hour >= min(start, end) && hour <= max(start, end)
    }
}

// MARK: - Day Relationship Enum

enum DayRelationship {
    case previous, same, next
}
