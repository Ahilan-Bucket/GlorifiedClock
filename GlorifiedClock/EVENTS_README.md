# Event Creation & Export Features

## 📅 New Features Implemented

### 1. Long Press & Drag to Create Events

**How it works:**
- **Long press** (0.5 seconds) on any time cell to start creating an event
- **Drag up or down** to select the duration
- **Release** to finalize and open the event editor

**Visual Feedback:**
- Purple highlight shows the selected time range
- Purple border indicates active selection
- Works on both home city and other city columns

### 2. Event Editor

**Features:**
- Edit event title, location, and notes
- View start time, end time, and duration
- Delete events
- All times are displayed in the city's timezone
- Respects 12h/24h format setting

**Fields:**
- **Title** - Event name
- **Start** - Automatically set from long press
- **End** - Automatically set from drag
- **Duration** - Calculated automatically
- **Location** - Optional event location
- **Notes** - Optional event notes

### 3. Event Display

**Visual Indicators:**
- **Purple dot** appears on time cells that have events
- Shows on both home city and other city columns
- Helps you quickly see when you have events scheduled

### 4. Export to .ics (iCalendar Format)

**How to export:**
- Events button appears in header (shows event count)
- Tap to open menu with export options:
  - **Export to Calendar** - Save .ics file
  - **Share Events** - Share via Messages, Email, AirDrop, etc.

**What gets exported:**
- All events in standard iCalendar (.ics) format
- Compatible with:
  - Apple Calendar
  - Google Calendar
  - Outlook
  - Any calendar app that supports .ics

**File format:**
```
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Glorified Clock//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:...
DTSTART:20250101T100000
DTEND:20250101T110000
SUMMARY:New Event
LOCATION:Office
DESCRIPTION:Meeting notes
END:VEVENT
END:VCALENDAR
```

## 📱 Usage Guide

### Creating an Event:
1. Long press on a time cell in any city column
2. Drag to select duration (can drag up or down)
3. Release to open event editor
4. Fill in event details
5. Tap "Save"

### Viewing Events:
- Purple dots indicate hours with events
- Events are tracked per city timezone

### Exporting Events:
1. Look for purple button in header (shows event count)
2. Tap the button
3. Choose "Export to Calendar" or "Share Events"
4. Select destination app or sharing method

### Deleting Events:
1. Tap on a time cell with an event
2. Or create a new event to access editor
3. Scroll down in event editor
4. Tap "Delete Event" (red button)

## 🎨 Visual Design

**Color Coding:**
- **Purple** - Event selection and event indicators
- **Blue gradient** - Home city current time
- **Orange** - Previous day cells
- **Green** - Next day cells

**Gestures:**
- Long press - Start event creation
- Drag - Select duration
- Tap city header - Set as home city
- Tap X - Remove city

## 🔧 Technical Details

**Files Added:**
- `Event.swift` - Event model with .ics export
- `EventEditorView.swift` - Event editing interface

**Files Modified:**
- `TimeViewModel.swift` - Event management logic
- `UnifiedTimelineGrid.swift` - Long press & drag gestures
- `ContentView.swift` - Export functionality

**Key Features:**
- Events are timezone-aware
- Drag gesture works vertically
- Visual feedback during selection
- Standard .ics format for compatibility
- Haptic feedback on event creation

Enjoy scheduling across timezones! 🌍⏰
