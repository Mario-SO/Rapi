import Foundation

// MARK: - Station Departures Response
struct StationDeparturesResponse: Codable {
    let stationFound: String
    let stationId: String
    let dateQueried: String
    let timeQueried: String
    let departures: [DepartureModel]
    
    enum CodingKeys: String, CodingKey {
        case stationFound = "station_found"
        case stationId = "station_id"
        case dateQueried = "date_queried"
        case timeQueried = "time_queried"
        case departures
    }
}

// MARK: - Departure Model
struct DepartureModel: Codable, Identifiable {
    let routeShortName: String
    let routeLongName: String
    let tripId: String
    let tripHeadsign: String
    let departureTime: String
    
    var id: String { tripId }
    
    enum CodingKeys: String, CodingKey {
        case routeShortName = "route_short_name"
        case routeLongName = "route_long_name"
        case tripId = "trip_id"
        case tripHeadsign = "trip_headsign"
        case departureTime = "departure_time"
    }
    
    // Format time from HH:MM:SS to HH:MM
    var formattedDepartureTime: String {
        let components = departureTime.split(separator: ":")
        if components.count >= 2 {
            return "\(components[0]):\(components[1])"
        }
        return departureTime
    }
}

// MARK: - Route Models
struct RouteModel: Codable, Identifiable {
    let routeId: String
    let routeShortName: String
    let routeLongName: String
    
    var id: String { routeId }
    
    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case routeShortName = "route_short_name"
        case routeLongName = "route_long_name"
    }
}

struct RouteDetailModel: Codable {
    let routeId: String
    let routeShortName: String
    let routeLongName: String
    let stops: [RouteStop]
    
    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case routeShortName = "route_short_name"
        case routeLongName = "route_long_name"
        case stops
    }
}

struct RouteStop: Codable, Identifiable {
    let stopId: String
    let stopName: String
    let stopSequence: Int
    
    var id: String { stopId }
    
    enum CodingKeys: String, CodingKey {
        case stopId = "stop_id"
        case stopName = "stop_name"
        case stopSequence = "stop_sequence"
    }
    
    // Custom decoder to handle stopSequence as String or Int
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stopId = try container.decode(String.self, forKey: .stopId)
        stopName = try container.decode(String.self, forKey: .stopName)
        
        // Try to decode stopSequence as Int first
        if let intValue = try? container.decode(Int.self, forKey: .stopSequence) {
            stopSequence = intValue
        } else {
            // If that fails, try to decode as String and convert to Int
            let stringValue = try container.decode(String.self, forKey: .stopSequence)
            guard let intValueFromString = Int(stringValue) else {
                throw DecodingError.dataCorruptedError(forKey: .stopSequence,
                                                     in: container,
                                                     debugDescription: "stop_sequence is not a valid Int or String convertible to Int")
            }
            stopSequence = intValueFromString
        }
    }
    
    // If you need to encode this model back to JSON and want stopSequence as a String:
    // func encode(to encoder: Encoder) throws {
    //     var container = encoder.container(keyedBy: CodingKeys.self)
    //     try container.encode(stopId, forKey: .stopId)
    //     try container.encode(stopName, forKey: .stopName)
    //     try container.encode(String(format: "%03d", stopSequence), forKey: .stopSequence) // Example formatting
    // }
}

// MARK: - API Error Responses
struct ApiErrorResponse: Codable {
    let error: String
    let details: String?
}

struct ApiMessageResponse: Codable {
    let message: String
    let departureStationUsed: String?
    let arrivalStationUsed: String?
    let dateQueried: String?
    let timeQueried: String?
    let info: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case departureStationUsed = "departure_station_used"
        case arrivalStationUsed = "arrival_station_used"
        case dateQueried = "date_queried"
        case timeQueried = "time_queried"
        case info
    }
} 