import Foundation

class MockTrainDataService {
    static let shared = MockTrainDataService()
    
    private init() {}
    
    // Mock stations data for our stations list
    let stations: [StationApiModel] = [
        StationApiModel(stopId: "05291", stopName: "A Caridá", stopLat: "43.547074", stopLon: "-6.827541"),
        StationApiModel(stopId: "05129", stopName: "A Cuqueira", stopLat: "43.6078760", stopLon: "-7.9218320"),
        StationApiModel(stopId: "05197", stopName: "A Veiga/Vegadeo", stopLat: "43.479667", stopLon: "-7.057327"),
        StationApiModel(stopId: "13118", stopName: "Abaroa-Sm", stopLat: "43.2258013", stopLon: "-2.8879643"),
        StationApiModel(stopId: "MADP", stopName: "Atocha Cercanías", stopLat: "40.406", stopLon: "-3.691"),
        StationApiModel(stopId: "SOL", stopName: "Madrid-Sol", stopLat: "40.417", stopLon: "-3.703"),
        StationApiModel(stopId: "CHAM", stopName: "Chamartín", stopLat: "40.472", stopLon: "-3.682"),
        StationApiModel(stopId: "NUEV", stopName: "Nuevos Ministerios", stopLat: "40.445", stopLon: "-3.692"),
        StationApiModel(stopId: "AERT4", stopName: "Aeropuerto T4", stopLat: "40.493", stopLon: "-3.592"),
        StationApiModel(stopId: "VALD", stopName: "Valdemoro", stopLat: "40.1962", stopLon: "-3.6788")
    ]
    
    // Function to simulate fetching the next train
    func fetchNextTrain(departureStationId: String, arrivalStationId: String, completion: @escaping (Result<NextTrainResponse, Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Find station names
            let depName = self.stations.first(where: { $0.id == departureStationId })?.stopName ?? "Unknown"
            let arrName = self.stations.first(where: { $0.id == arrivalStationId })?.stopName ?? "Unknown"
            
            // Create current date components
            let now = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentDate = dateFormatter.string(from: now)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            let currentTime = timeFormatter.string(from: now)
            
            // Mock next train data
            let nextTrain = Train(
                routeShortName: "C3",
                routeLongName: "Aranjuez-Chamartín - Clara Campoamor",
                tripId: "1059D27001C3",
                tripHeadsign: "",
                serviceId: "1059D",
                departureStationDepartureTime: "07:35:00",
                arrivalStationArrivalTime: "08:08:00"
            )
            
            let response = NextTrainResponse(
                departureStationNameQuery: depName,
                arrivalStationNameQuery: arrName,
                departureStationFound: depName,
                arrivalStationFound: arrName,
                dateQueried: currentDate,
                timeQueried: currentTime,
                nextTrain: nextTrain
            )
            
            completion(.success(response))
        }
    }
    
    // Function to simulate fetching the timetable
    func fetchTimetable(departureStationId: String, arrivalStationId: String, date: Date = Date(), completion: @escaping (Result<TimetableResponse, Error>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Find station names
            let depName = self.stations.first(where: { $0.id == departureStationId })?.stopName ?? "Unknown"
            let arrName = self.stations.first(where: { $0.id == arrivalStationId })?.stopName ?? "Unknown"
            
            // Create date string
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            
            // Generate sample timetable
            var trains: [Train] = []
            
            // Create trains at 30 minute intervals
            for hour in 5...23 {
                for minute in [5, 35] {
                    let depTime = String(format: "%02d:%02d:00", hour, minute)
                    let arrTime = String(format: "%02d:%02d:00", hour, minute + 33)
                    
                    let train = Train(
                        routeShortName: "C3",
                        routeLongName: "Aranjuez-Chamartín - Clara Campoamor",
                        tripId: "1059D\(hour)\(minute)C3",
                        tripHeadsign: "",
                        serviceId: "1059D",
                        departureStationDepartureTime: depTime,
                        arrivalStationArrivalTime: arrTime
                    )
                    
                    trains.append(train)
                }
            }
            
            let response = TimetableResponse(
                departureStationNameQuery: depName,
                arrivalStationNameQuery: arrName,
                departureStationFound: depName,
                arrivalStationFound: arrName,
                dateQueried: dateString,
                timetable: trains
            )
            
            completion(.success(response))
        }
    }
    
    enum MockServiceError: Error {
        case invalidStation
        case noTrainsFound
        case networkError
    }
} 