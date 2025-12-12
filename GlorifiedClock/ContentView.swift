//
//  ContentView.swift
//  GlorifiedClock
//
//  Created by Ahilan Kumaresan on 11/12/2025.
//

import SwiftUI

// MARK: - Data Model

struct CityTime: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let timeZone: TimeZone
    var isHome: Bool
}

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

// MARK: - Scroll Sync Coordinator

class ScrollSyncCoordinator: ObservableObject {
    @Published var scrollOffset: CGFloat = 0
    var isInternalUpdate = false
}

// MARK: - Synchronized Scroll View (Simplified)

struct SyncedScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    @ObservedObject var coordinator: ScrollSyncCoordinator
    let id: String
    
    init(id: String, coordinator: ScrollSyncCoordinator, @ViewBuilder content: () -> Content) {
        self.id = id
        self.coordinator = coordinator
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        scrollView.alwaysBounceHorizontal = true
        
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        context.coordinator.scrollView = scrollView
        context.coordinator.hostingController = hostingController
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
        
        if !context.coordinator.isScrolling {
            coordinator.isInternalUpdate = true
            scrollView.contentOffset.x = coordinator.scrollOffset
            coordinator.isInternalUpdate = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(id: id, syncCoordinator: coordinator)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        let id: String
        let syncCoordinator: ScrollSyncCoordinator
        weak var scrollView: UIScrollView?
        var hostingController: UIHostingController<Content>?
        var isScrolling = false
        
        init(id: String, syncCoordinator: ScrollSyncCoordinator) {
            self.id = id
            self.syncCoordinator = syncCoordinator
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !syncCoordinator.isInternalUpdate else { return }
            
            if scrollView.isDragging || scrollView.isDecelerating {
                isScrolling = true
                syncCoordinator.scrollOffset = scrollView.contentOffset.x
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                isScrolling = false
            }
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            isScrolling = false
        }
    }
}

// MARK: - Unified Timeline Grid

struct UnifiedTimelineGrid: View {
    @ObservedObject var viewModel: TimeViewModel
    @StateObject private var scrollCoordinator = ScrollSyncCoordinator()
    
    private let columnWidth: CGFloat = 90
    private let homeColumnWidth: CGFloat = 110
    
    var body: some View {
        VStack(spacing: 0) {
            // HEADER ROW
            headerRow
            
            Divider()
            
            // TIME GRID
            timeGrid
        }
    }
    
    private var headerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            // Home city header
            if let home = viewModel.homeCity {
                homeCityHeader(home)
                    .padding(.leading, 16)
            }
            
            // Other cities header (scrollable)
            SyncedScrollView(id: "header", coordinator: scrollCoordinator) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.cities.dropFirst())) { city in
                        cityHeader(city)
                    }
                    
                    addCityButton
                }
                .padding(.trailing, 16)
            }
            .frame(height: 85)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    private func homeCityHeader(_ home: CityTime) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "house.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
                Text(home.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            
            Text(viewModel.timezoneAbbreviation(for: home))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            
            Divider().padding(.horizontal, 8)
            
            Text(viewModel.currentDateString(for: home))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(viewModel.currentTimeString(for: home))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .frame(width: homeColumnWidth, height: 85)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .cyan.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .blue.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private func cityHeader(_ city: CityTime) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                Text(city.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(viewModel.timezoneAbbreviation(for: city))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Divider().padding(.horizontal, 8)
                
                if let home = viewModel.homeCity {
                    let isDifferent = viewModel.isDifferentDay(city: city, from: home)
                    Text(viewModel.currentDateString(for: city))
                        .font(.system(size: 11,
                                      weight: isDifferent ? .bold : .medium,
                                      design: .rounded))
                        .foregroundStyle(isDifferent ? .orange : .primary)
                }
                
                Text(viewModel.currentTimeString(for: city))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: columnWidth, height: 85)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.setHome(city)
                }
            }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.removeCity(city)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white, .red)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .offset(x: -4, y: 4)
        }
    }
    
    private var addCityButton: some View {
        Button {
            viewModel.showingAddCity = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Add")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(width: columnWidth, height: 85)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.blue.opacity(0.2),
                                    style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    )
            )
        }
    }
    
    private var timeGrid: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack(alignment: .top, spacing: 12) {
                // Home city column
                if let home = viewModel.homeCity {
                    VStack(spacing: 0) {
                        ForEach(viewModel.hours, id: \.self) { hour in
                            homeTimeCell(home: home, hour: hour)
                        }
                    }
                    .padding(.leading, 16)
                }
                
                // Other cities columns (scrollable)
                SyncedScrollView(id: "grid", coordinator: scrollCoordinator) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.cities.dropFirst())) { city in
                            VStack(spacing: 0) {
                                ForEach(viewModel.hours, id: \.self) { hour in
                                    cityTimeCell(city: city, hour: hour)
                                }
                            }
                        }
                        
                        Color.clear.frame(width: columnWidth)
                    }
                    .padding(.trailing, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 8)
        }
    }
    
    private func homeTimeCell(home: CityTime, hour: Int) -> some View {
        let base = viewModel.baseDate(for: hour)
        let isNow = hour == viewModel.currentHourInHome()
        
        return ZStack {
            if viewModel.showRipple && isNow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .scaleEffect(viewModel.showRipple ? 2 : 0)
                    .opacity(viewModel.showRipple ? 0 : 1)
            }
            
            HStack(spacing: 6) {
                if isNow {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 8, height: 8)
                        .shadow(color: .red.opacity(0.6), radius: 4)
                }
                
                Text(viewModel.formattedTime(base, for: home))
                    .font(.system(size: 19,
                                  weight: isNow ? .bold : .semibold,
                                  design: .rounded))
            }
            .frame(width: homeColumnWidth, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isNow
                        ? LinearGradient(
                            colors: [Color.blue.opacity(0.15), Color.cyan.opacity(0.08)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color(UIColor.systemBackground)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .padding(.vertical, 2)
        }
    }
    
    private func cityTimeCell(city: CityTime, hour: Int) -> some View {
        let base = viewModel.baseDate(for: hour)
        let isNowRow = hour == viewModel.currentHourInHome()
        
        return Text(viewModel.formattedTime(base, for: city))
            .font(.system(size: 17,
                          weight: isNowRow ? .semibold : .medium,
                          design: .rounded))
            .frame(width: columnWidth, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        isNowRow
                        ? Color.blue.opacity(0.10)
                        : Color(UIColor.systemBackground)
                    )
            )
            .padding(.vertical, 2)
    }
}

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

// MARK: - Main Content View

struct ContentView: View {
    @StateObject private var viewModel = TimeViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                Divider()
                UnifiedTimelineGrid(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingAddCity) {
                AddCityView(viewModel: viewModel)
            }
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Glorified Clock")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Vannakam, your world, aligned.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.use24HourFormat.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                    Text(viewModel.use24HourFormat ? "24h" : "12h")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
