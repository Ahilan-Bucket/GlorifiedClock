
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
