
//
//  ScrollSyncCoordinator.swift
//  GlorifiedClock
//

import SwiftUI

// MARK: - Scroll Sync Coordinator

class ScrollSyncCoordinator: ObservableObject {
    @Published var scrollOffset: CGFloat = 0
    var isInternalUpdate = false
}
