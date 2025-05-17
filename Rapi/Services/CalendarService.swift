import EventKit
import Foundation
import os.log // Import os.log for logging

class CalendarService {
    static let shared = CalendarService()
    private let eventStore = EKEventStore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "CalendarService") // Logger instance
    
    private init() {}
    
    // Helper for pre-iOS 17 calendar access
    private func requestLegacyCalendarAccess() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            eventStore.requestAccess(to: .event) { (granted, error) in // This will show a warning if building with iOS 17 SDK
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func addTrainEvent(train: Train, departureStation: String, arrivalStation: String, leaveByTime: String) async throws -> Bool {
        // Log current authorization status before requesting
        let currentStatus = EKEventStore.authorizationStatus(for: .event)
        logger.info("Current calendar authorization status: \(currentStatus.rawValue)")

        let granted: Bool
        if #available(iOS 17.0, *) {
            logger.info("Requesting calendar access using iOS 17+ API (requestFullAccessToEvents)")
            granted = try await eventStore.requestFullAccessToEvents()
        } else {
            logger.info("Requesting calendar access using legacy API (requestAccess to: .event)")
            granted = try await requestLegacyCalendarAccess()
        }
        logger.info("Calendar access request returned: \(granted)")

        guard granted else {
            logger.error("Calendar access denied.")
            throw NSError(domain: "CalendarService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied"])
        }
        
        logger.info("Calendar access granted. Proceeding to create event.")
        // Create event
        let event = EKEvent(eventStore: eventStore)
        event.title = "\(departureStation) → \(arrivalStation)"
        event.notes = """
        Train: \(train.routeShortName)
        Duration: \(train.durationInMinutes) minutes
        Leave by: \(leaveByTime)
        """
        
        // Set start and end dates
        guard let startDate = train.departureDateTime(on: Date()),
              let endDate = train.arrivalDateTime(on: Date()) else {
            logger.error("Failed to get valid start/end dates for calendar event from train object.")
            throw NSError(domain: "CalendarService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid train time data for calendar event."])
        }
        event.startDate = startDate
        event.endDate = endDate
        
        // Set calendar
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            logger.error("No default calendar available.")
            throw NSError(domain: "CalendarService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No default calendar available"])
        }
        event.calendar = calendar
        
        // Parse leave by time to create alert
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        if let leaveByDate = formatter.date(from: leaveByTime) {
            let components = Calendar.current.dateComponents([.hour, .minute], from: leaveByDate)
            let today = Calendar.current.startOfDay(for: Date())
            if let alertTime = Calendar.current.date(byAdding: components, to: today) {
                let alarm = EKAlarm(absoluteDate: alertTime)
                event.addAlarm(alarm)
                logger.info("Alarm added for event at \(alertTime).")
            } else {
                logger.warning("Could not calculate alert time from leaveByDate.")
            }
        } else {
            logger.warning("Could not parse leaveByTime string: \(leaveByTime)")
        }
        
        // Save event
        try eventStore.save(event, span: .thisEvent)
        logger.info("Event saved successfully to calendar.")
        return true
    }
} 
