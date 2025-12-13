
//
//  CityTime.swift
//  GlorifiedClock
//

import Foundation

// MARK: - Data Model

struct CityTime: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let timeZone: TimeZone
    var isHome: Bool
}
