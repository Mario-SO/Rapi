import Foundation
import SwiftUI

class RouteListViewModel: ObservableObject {
    @Published var routes: [RouteModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    // Fetch all routes
    func fetchRoutes() {
        isLoading = true
        errorMessage = nil
        
        apiService.fetchAllRoutes { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let routes):
                    self?.routes = routes
                case .failure(let error):
                    self?.errorMessage = "Failed to load routes: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Alternative implementation using async/await
    @MainActor
    func fetchRoutesAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            routes = try await apiService.fetchAllRoutes()
        } catch {
            errorMessage = "Failed to load routes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Fetch route details
    func fetchRouteDetails(routeId: String) async throws -> RouteDetailModel {
        return try await apiService.fetchRoute(byId: routeId)
    }
} 