import Foundation

// MARK: - Next Train API Response
struct NextTrainResponse: Codable {
    let departureStationNameQuery: String
    let arrivalStationNameQuery: String
    let departureStationFound: String
    let arrivalStationFound: String
    let dateQueried: String
    let timeQueried: String
    let nextTrain: Train
    
    enum CodingKeys: String, CodingKey {
        case departureStationNameQuery = "departure_station_name_query"
        case arrivalStationNameQuery = "arrival_station_name_query"
        case departureStationFound = "departure_station_found"
        case arrivalStationFound = "arrival_station_found"
        case dateQueried = "date_queried"
        case timeQueried = "time_queried"
        case nextTrain = "next_train"
    }
}

// MARK: - Timetable API Response
struct TimetableResponse: Codable {
    let departureStationNameQuery: String
    let arrivalStationNameQuery: String
    let departureStationFound: String
    let arrivalStationFound: String
    let dateQueried: String
    let timetable: [Train]
    
    enum CodingKeys: String, CodingKey {
        case departureStationNameQuery = "departure_station_name_query"
        case arrivalStationNameQuery = "arrival_station_name_query"
        case departureStationFound = "departure_station_found"
        case arrivalStationFound = "arrival_station_found"
        case dateQueried = "date_queried"
        case timetable
    }
}

// MARK: - Train Details
struct Train: Codable, Identifiable {
    let routeShortName: String
    let routeLongName: String
    let tripId: String
    let tripHeadsign: String
    let serviceId: String
    let departureStationDepartureTime: String
    let arrivalStationArrivalTime: String
    
    var id: String { tripId }
    
    enum CodingKeys: String, CodingKey {
        case routeShortName = "route_short_name"
        case routeLongName = "route_long_name"
        case tripId = "trip_id"
        case tripHeadsign = "trip_headsign"
        case serviceId = "service_id"
        case departureStationDepartureTime = "departure_station_departure_time"
        case arrivalStationArrivalTime = "arrival_station_arrival_time"
    }
    
    // Computed properties for formatting
    var formattedDepartureTime: String {
        return formatTime(departureStationDepartureTime)
    }
    
    var formattedArrivalTime: String {
        return formatTime(arrivalStationArrivalTime)
    }
    
    var durationInMinutes: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        guard let departure = formatter.date(from: departureStationDepartureTime),
              let arrival = formatter.date(from: arrivalStationArrivalTime) else {
            return 0
        }
        
        return Int(arrival.timeIntervalSince(departure) / 60)
    }
    
    // New computed properties for Date objects
    func departureDateTime(on day: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        // Parse the time string
        guard let timePortion = formatter.date(from: departureStationDepartureTime) else {
            return nil
        }
        
        // Get hour, minute, second from the parsed time
        let timeComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: timePortion)
        
        // Get year, month, day from the input 'day'
        let dayComponents = Calendar.current.dateComponents([.year, .month, .day], from: day)
        
        // Combine them
        var combinedComponents = DateComponents()
        combinedComponents.year = dayComponents.year
        combinedComponents.month = dayComponents.month
        combinedComponents.day = dayComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        return Calendar.current.date(from: combinedComponents)
    }
    
    func arrivalDateTime(on day: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        // Parse the time string
        guard let timePortion = formatter.date(from: arrivalStationArrivalTime) else {
            return nil
        }
        
        // Get hour, minute, second from the parsed time
        let timeComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: timePortion)
        
        // Get year, month, day from the input 'day'
        let dayComponents = Calendar.current.dateComponents([.year, .month, .day], from: day)
        
        // Combine them
        var combinedComponents = DateComponents()
        combinedComponents.year = dayComponents.year
        combinedComponents.month = dayComponents.month
        combinedComponents.day = dayComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        return Calendar.current.date(from: combinedComponents)
    }
    
    private func formatTime(_ timeString: String) -> String {
        // Convert from HH:mm:ss to HH:mm
        let components = timeString.split(separator: ":")
        if components.count >= 2 {
            return "\(components[0]):\(components[1])"
        }
        return timeString
    }
}

// MARK: - Station Data Model
struct StationApiModel: Codable, Identifiable {
    let stopId: String
    let stopName: String
    let stopLat: String
    let stopLon: String
    
    var id: String { stopId }
    
    enum CodingKeys: String, CodingKey {
        case stopId = "stop_id"
        case stopName = "stop_name"
        case stopLat = "stop_lat"
        case stopLon = "stop_lon"
    }
}

// MARK: - User Preferences
struct UserDefaultStations: Codable {
    var departureStationId: String
    var departureStationName: String
    var arrivalStationId: String
    var arrivalStationName: String
} 