import Foundation

class APIService {
    static let shared = APIService()
    
    private init() {}
    
    private let baseURL = "https://project-polaris-proud-voice-5352.fly.dev"
    
    // MARK: - Health Check
    func healthCheck(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let message = String(data: data, encoding: .utf8) else {
                completion(.failure(APIError.noData))
                return
            }
            
            completion(.success(message))
        }.resume()
    }
    
    // Async version
    func healthCheck() async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let message = String(data: data, encoding: .utf8) else {
            throw APIError.noData
        }
        
        return message
    }
    
    // MARK: - Stations API
    
    // Get all stations
    func fetchAllStations(searchQuery: String? = nil, completion: @escaping (Result<[StationApiModel], Error>) -> Void) {
        var urlString = "\(baseURL)/stations"
        
        if let query = searchQuery, !query.isEmpty {
            urlString += "?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let stations = try JSONDecoder().decode([StationApiModel].self, from: data)
                completion(.success(stations))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Async version
    func fetchAllStations(searchQuery: String? = nil) async throws -> [StationApiModel] {
        var urlString = "\(baseURL)/stations"
        
        if let query = searchQuery, !query.isEmpty {
            urlString += "?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([StationApiModel].self, from: data)
    }
    
    // Get station by ID
    func fetchStation(byId stationId: String, completion: @escaping (Result<StationApiModel, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/stations/\(stationId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let station = try JSONDecoder().decode(StationApiModel.self, from: data)
                completion(.success(station))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Async version
    func fetchStation(byId stationId: String) async throws -> StationApiModel {
        guard let url = URL(string: "\(baseURL)/stations/\(stationId)") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(StationApiModel.self, from: data)
    }
    
    // Get station departures
    func fetchStationDepartures(stationId: String, date: String? = nil, time: String? = nil, completion: @escaping (Result<StationDeparturesResponse, Error>) -> Void) {
        var urlComponents = URLComponents(string: "\(baseURL)/stations/\(stationId)/departures")
        
        var queryItems: [URLQueryItem] = []
        if let date = date {
            queryItems.append(URLQueryItem(name: "date", value: date))
        }
        if let time = time {
            queryItems.append(URLQueryItem(name: "time", value: time))
        }
        
        if !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }
        
        guard let url = urlComponents?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let departures = try JSONDecoder().decode(StationDeparturesResponse.self, from: data)
                completion(.success(departures))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Async version
    func fetchStationDepartures(stationId: String, date: String? = nil, time: String? = nil) async throws -> StationDeparturesResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/stations/\(stationId)/departures")
        
        var queryItems: [URLQueryItem] = []
        if let date = date {
            queryItems.append(URLQueryItem(name: "date", value: date))
        }
        if let time = time {
            queryItems.append(URLQueryItem(name: "time", value: time))
        }
        
        if !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }
        
        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(StationDeparturesResponse.self, from: data)
    }
    
    // MARK: - Routes API
    
    // Get all routes
    func fetchAllRoutes(completion: @escaping (Result<[RouteModel], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/routes") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let routes = try JSONDecoder().decode([RouteModel].self, from: data)
                completion(.success(routes))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Async version
    func fetchAllRoutes() async throws -> [RouteModel] {
        guard let url = URL(string: "\(baseURL)/routes") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([RouteModel].self, from: data)
    }
    
    // Get route by ID
    func fetchRoute(byId routeId: String, completion: @escaping (Result<RouteDetailModel, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/routes/\(routeId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let route = try JSONDecoder().decode(RouteDetailModel.self, from: data)
                completion(.success(route))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Async version
    func fetchRoute(byId routeId: String) async throws -> RouteDetailModel {
        // Make sure the route ID is properly formatted - trim any whitespace
        let cleanedRouteId = routeId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let url = URL(string: "\(baseURL)/routes/\(cleanedRouteId)") else {
            print("Invalid URL for route ID: \(cleanedRouteId)")
            throw APIError.invalidURL
        }
        
        print("Fetching route with URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Print response status code for debugging
        if let httpResponse = response as? HTTPURLResponse {
            print("Route API Response for ID \(cleanedRouteId): \(httpResponse.statusCode)")
            
            // 404 - Route not found
            if httpResponse.statusCode == 404 {
                let dataString = String(data: data, encoding: .utf8) ?? "No data"
                print("Route not found response: \(dataString)")
                
                // Try to decode as API error response
                if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                    throw NSError(domain: "APIError", 
                                 code: 404, 
                                 userInfo: [NSLocalizedDescriptionKey: apiError.error])
                }
                
                throw NSError(domain: "APIError", 
                             code: 404, 
                             userInfo: [NSLocalizedDescriptionKey: "Route with ID '\(cleanedRouteId)' not found."])
            }
            
            // Other error responses
            if httpResponse.statusCode >= 400 {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Error response: \(errorString)")
                
                // Try to decode as API error response
                if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                    throw NSError(domain: "APIError", 
                                 code: httpResponse.statusCode, 
                                 userInfo: [NSLocalizedDescriptionKey: "API Error: \(apiError.error)"])
                }
                
                throw APIError.serverError
            }
        }
        
        do {
            let route = try JSONDecoder().decode(RouteDetailModel.self, from: data)
            print("Successfully decoded route with ID \(cleanedRouteId): \(route.routeShortName) - \(route.stops.count) stops")
            return route
        } catch {
            print("Decoding error for route \(cleanedRouteId): \(error)")
            print("Data received: \(String(data: data, encoding: .utf8) ?? "No data")")
            throw error
        }
    }
    
    // MARK: - Timetables API
    
    // Get timetable between stations
    func fetchTimetable(departureStation: String, arrivalStation: String, date: String? = nil, completion: @escaping (Result<TimetableResponse, Error>) -> Void) {
        // URL encode station names/IDs for path parameters
        guard let encodedDeparture = departureStation.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedArrival = arrivalStation.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/timetable/\(encodedDeparture)/\(encodedArrival)")
        
        if let date = date {
            urlComponents?.queryItems = [URLQueryItem(name: "date", value: date)]
        }
        
        guard let url = urlComponents?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let timetable = try JSONDecoder().decode(TimetableResponse.self, from: data)
                completion(.success(timetable))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Async version
    func fetchTimetable(departureStation: String, arrivalStation: String, date: String? = nil) async throws -> TimetableResponse {
        // URL encode station names/IDs for path parameters
        guard let encodedDeparture = departureStation.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedArrival = arrivalStation.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw APIError.invalidURL
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/timetable/\(encodedDeparture)/\(encodedArrival)")
        
        if let date = date {
            urlComponents?.queryItems = [URLQueryItem(name: "date", value: date)]
        }
        
        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Print response status code for debugging
        if let httpResponse = response as? HTTPURLResponse {
            print("Timetable API Response: \(httpResponse.statusCode)")
            
            // Check if we got an error response
            if httpResponse.statusCode >= 400 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorString)")
                    throw APIError.serverError
                }
            }
        }
        
        return try JSONDecoder().decode(TimetableResponse.self, from: data)
    }
    
    // Get next train between stations
    func fetchNextTrain(departureStation: String, arrivalStation: String, completion: @escaping (Result<NextTrainResponse, Error>) -> Void) {
        // URL encode station names/IDs for path parameters
        guard let encodedDeparture = departureStation.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedArrival = arrivalStation.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/timetable/\(encodedDeparture)/\(encodedArrival)/next") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let nextTrain = try JSONDecoder().decode(NextTrainResponse.self, from: data)
                completion(.success(nextTrain))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Async version
    func fetchNextTrain(departureStation: String, arrivalStation: String) async throws -> NextTrainResponse {
        // URL encode station names/IDs for path parameters
        guard let encodedDeparture = departureStation.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedArrival = arrivalStation.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw APIError.invalidURL
        }
        
        guard let url = URL(string: "\(baseURL)/timetable/\(encodedDeparture)/\(encodedArrival)/next") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Print response status code for debugging
        if let httpResponse = response as? HTTPURLResponse {
            print("Next Train API Response: \(httpResponse.statusCode)")
            
            // Check if we got an error response
            if httpResponse.statusCode >= 400 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorString)")
                    throw APIError.serverError
                }
            }
        }
        
        return try JSONDecoder().decode(NextTrainResponse.self, from: data)
    }
    
    // MARK: - Error Handling
    enum APIError: Error {
        case invalidURL
        case noData
        case decodingError
        case networkError
        case serverError
    }
} 