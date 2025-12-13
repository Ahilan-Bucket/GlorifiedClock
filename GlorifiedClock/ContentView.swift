//
//  ContentView.swift
//  GlorifiedClock
//
//  Created by Ahilan Kumaresan on 11/12/2025.
//

import SwiftUI

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
            .sheet(isPresented: $viewModel.showingEventEditor) {
                if let event = viewModel.eventBeingEdited {
                    EventEditorView(viewModel: viewModel, event: event)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
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
                    
                    // Show which date we're viewing if not today
                    if !viewModel.isViewingToday(), let home = viewModel.homeCity {
                        Text("Viewing \(viewModel.viewedDateString(for: home))")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.orange)
                    } else {
                        Text("Vannakam, Let's get your world, aligned.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
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
            
            // Calendar and Today button row
            HStack(spacing: 12) {
                // Calendar Date Picker
                DatePicker(
                    "",
                    selection: $viewModel.selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: viewModel.selectedDate) { oldValue, newValue in
                    viewModel.selectDate(newValue)
                }
                .frame(maxWidth: 140)
                
                // Today Button
                Button {
                    viewModel.goToToday()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 14))
                        Text("Today")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        viewModel.isViewingToday()
                        ? LinearGradient(
                            colors: [.gray, .gray.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: viewModel.isViewingToday() ? .gray.opacity(0.3) : .green.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(viewModel.isViewingToday())
                
                Spacer()
                
                // Export Events Button
                if !viewModel.events.isEmpty {
                    Menu {
                        Button {
                            exportToICS()
                        } label: {
                            Label("Export to Calendar (.ics)", systemImage: "calendar.badge.plus")
                        }
                        
                        Button {
                            shareICS()
                        } label: {
                            Label("Share Events", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 14))
                            Text("\(viewModel.events.count)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
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
    
    // MARK: - Export Functions
    
    private func exportToICS() {
        let icsContent = viewModel.exportEventsToICS()
        let fileName = "events_\(Date().timeIntervalSince1970).ics"
        
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            do {
                try icsContent.write(to: fileURL, atomically: true, encoding: .utf8)
                
                // Present activity view controller to save/share the file
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    rootViewController.present(activityVC, animated: true)
                }
            } catch {
                print("Error saving ICS file: \(error)")
            }
        }
    }
    
    private func shareICS() {
        exportToICS()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
