
//
//  UnifiedTimelineGrid.swift
//  GlorifiedClock
//

import SwiftUI

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
