import Foundation
import SwiftUI

class StationListViewModel: ObservableObject {
    @Published var stations: [StationApiModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    
    private let apiService = APIService.shared
    
    // Fetch stations with optional search query
    func fetchStations() {
        isLoading = true
        errorMessage = nil
        
        let query = searchQuery.isEmpty ? nil : searchQuery
        
        apiService.fetchAllStations(searchQuery: query) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let stations):
                    self?.stations = stations
                case .failure(let error):
                    self?.errorMessage = "Failed to load stations: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Alternative implementation using async/await
    @MainActor
    func fetchStationsAsync() async {
        isLoading = true
        errorMessage = nil
        
        let query = searchQuery.isEmpty ? nil : searchQuery
        
        do {
            stations = try await apiService.fetchAllStations(searchQuery: query)
        } catch {
            errorMessage = "Failed to load stations: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Fetch next train between two stations
    func fetchNextTrain(departureStationId: String, arrivalStationId: String, completion: @escaping (Result<NextTrainResponse, Error>) -> Void) {
        apiService.fetchNextTrain(departureStation: departureStationId, arrivalStation: arrivalStationId, completion: completion)
    }
    
    // Fetch timetable between two stations
    func fetchTimetable(departureStationId: String, arrivalStationId: String, date: String? = nil, completion: @escaping (Result<TimetableResponse, Error>) -> Void) {
        apiService.fetchTimetable(departureStation: departureStationId, arrivalStation: arrivalStationId, date: date, completion: completion)
    }
} 