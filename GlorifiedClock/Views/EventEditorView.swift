//
//  EventEditorView.swift
//  GlorifiedClock
//

import SwiftUI

struct EventEditorView: View {
    @ObservedObject var viewModel: TimeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var location: String
    @State private var notes: String
    
    let event: TimeEvent
    
    init(viewModel: TimeViewModel, event: TimeEvent) {
        self.viewModel = viewModel
        self.event = event
        _title = State(initialValue: event.title)
        _location = State(initialValue: event.location)
        _notes = State(initialValue: event.notes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    
                    HStack {
                        Text("Start")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formattedDate(event.startDate))
                    }
                    
                    HStack {
                        Text("End")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formattedDate(event.endDate))
                    }
                    
                    HStack {
                        Text("Duration")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(durationString)
                            .foregroundStyle(.blue)
                    }
                }
                
                Section("Additional Info") {
                    TextField("Location", text: $location)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(role: .destructive) {
                        viewModel.deleteEvent(event)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Event")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updatedEvent = event
                        updatedEvent.title = title
                        updatedEvent.location = location
                        updatedEvent.notes = notes
                        viewModel.saveEvent(updatedEvent)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = event.cityTimeZone
        formatter.dateFormat = viewModel.use24HourFormat ? "MMM d, HH:mm" : "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    private var durationString: String {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}
