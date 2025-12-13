//
//  Event.swift
//  GlorifiedClock
//

import Foundation

// MARK: - Event Model

struct TimeEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String
    var notes: String
    var cityTimeZone: TimeZone
    
    init(
        id: UUID = UUID(),
        title: String = "New Event",
        startDate: Date,
        endDate: Date,
        location: String = "",
        notes: String = "",
        cityTimeZone: TimeZone
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.cityTimeZone = cityTimeZone
    }
    
    // MARK: - iCalendar Export
    
    func toICS() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.timeZone = cityTimeZone
        
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        let now = formatter.string(from: Date())
        
        // Escape special characters in text fields
        let escapedTitle = title.replacingOccurrences(of: "\n", with: "\\n")
        let escapedNotes = notes.replacingOccurrences(of: "\n", with: "\\n")
        let escapedLocation = location.replacingOccurrences(of: "\n", with: "\\n")
        
        return """
        BEGIN:VEVENT
        UID:\(id.uuidString)
        DTSTAMP:\(now)
        DTSTART:\(start)
        DTEND:\(end)
        SUMMARY:\(escapedTitle)
        LOCATION:\(escapedLocation)
        DESCRIPTION:\(escapedNotes)
        END:VEVENT
        """
    }
}

// MARK: - Event Collection Export

extension Array where Element == TimeEvent {
    func toICSFile() -> String {
        let events = self.map { $0.toICS() }.joined(separator: "\n")
        
        return """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Glorified Clock//EN
        CALSCALE:GREGORIAN
        \(events)
        END:VCALENDAR
        """
    }
}
