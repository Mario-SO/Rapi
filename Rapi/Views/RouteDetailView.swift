import SwiftUI
import MapKit

struct RouteDetailView: View {
    let routeId: String
    let routeName: String
    
    // Format route name to properly space hyphens with more aggressive cleaning
    private var formattedRouteName: String {
        // First remove all excess whitespace, then format properly
        let trimmed = routeName.trimmingCharacters(in: .whitespaces)
        
        // Step 1: Collapse all whitespace to single spaces
        let noExtraSpaces = trimmed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Step 2: Replace hyphens with properly spaced hyphens
        let properlySpacedHyphens = noExtraSpaces
            .replacingOccurrences(of: "\\s*-\\s*", with: " - ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        return properlySpacedHyphens
    }
    
    @State private var routeDetail: RouteDetailModel?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.416775, longitude: -3.703790), // Default to Madrid
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var stopLocations: [StopLocation] = []
    
    // API service
    private let apiService = APIService.shared
    
    struct StopLocation: Identifiable {
        let id: String
        let name: String
        let coordinate: CLLocationCoordinate2D
        let sequence: Int
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Route name
                Text(formattedRouteName)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // Route ID
                Text("Route ID: \(routeId)")
                    .padding(.horizontal)
                
                // Loading/Error state
                if isLoading {
                    ProgressView("Loading route details...")
                        .padding()
                        .frame(maxWidth: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 8) {
                        Text("Failed to load route details:")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                        
                        Button {
                            loadRouteDetails()
                        } label: {
                            Text("Retry")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                } else if let routeDetail = routeDetail {
                    // Show map if we have stop locations with coordinates
                    if !stopLocations.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Route Map")
                                .font(.title2)
                                .padding(.top, 8)
                                .padding(.horizontal)
                            
                            Map(initialPosition: .region(mapRegion)) {
                                ForEach(stopLocations) { stop in
                                    Marker(stop.name, coordinate: stop.coordinate)
                                        .tint(.blue)
                                }
                                
                                // Add a path between stops if more than one stop
                                if stopLocations.count > 1 {
                                    let sortedLocations = stopLocations.sorted { $0.sequence < $1.sequence }
                                    let coordinates = sortedLocations.map { $0.coordinate }
                                    
                                    MapPolyline(coordinates: coordinates)
                                        .stroke(.blue, lineWidth: 3)
                                }
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Stops list
                    VStack(alignment: .leading) {
                        Text("Stops")
                            .font(.title2)
                            .padding(.top, 20)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(routeDetail.stops.sorted(by: { $0.stopSequence < $1.stopSequence })) { stop in
                                RouteStopRow(stop: stop)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                
                                if stop.stopId != routeDetail.stops.sorted(by: { $0.stopSequence < $1.stopSequence }).last?.stopId {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .navigationTitle("Route Details")
        .onAppear {
            loadRouteDetails()
        }
    }
    
    private func loadRouteDetails() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("Attempting to fetch route with ID: \(routeId)")
                let details = try await apiService.fetchRoute(byId: routeId)
                print("Successfully fetched route: \(details.routeId) with \(details.stops.count) stops")
                
                // Now that we have the route details, let's fetch coordinates for the stops
                await fetchStopCoordinates(for: details.stops)
                
                await MainActor.run {
                    routeDetail = details
                    isLoading = false
                    
                    // Update map region if we have stops with coordinates
                    if !stopLocations.isEmpty {
                        updateMapRegion()
                    }
                }
            } catch {
                print("Error fetching route details: \(error)")
                await MainActor.run {
                    // Create a more user-friendly error message
                    if let nsError = error as? NSError, nsError.domain == "APIError" {
                        if nsError.code == 404 {
                            errorMessage = "The route data couldn't be found because it is missing."
                        } else {
                            errorMessage = nsError.localizedDescription
                        }
                    } else if let urlError = error as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet:
                            errorMessage = "Please check your internet connection and try again."
                        case .timedOut:
                            errorMessage = "Request timed out. Please try again."
                        default:
                            errorMessage = "Network error: \(urlError.localizedDescription)"
                        }
                    } else {
                        errorMessage = "Failed to load route details: \(error.localizedDescription)"
                    }
                    
                    isLoading = false
                }
            }
        }
    }
    
    private func fetchStopCoordinates(for stops: [RouteStop]) async {
        var locations: [StopLocation] = []
        
        for stop in stops {
            do {
                let stationDetails = try await apiService.fetchStation(byId: stop.stopId)
                
                if let lat = Double(stationDetails.stopLat), 
                   let lon = Double(stationDetails.stopLon) {
                    let location = StopLocation(
                        id: stationDetails.stopId,
                        name: stationDetails.stopName,
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        sequence: stop.stopSequence
                    )
                    locations.append(location)
                }
            } catch {
                print("Error fetching coordinates for station \(stop.stopId): \(error)")
                // Continue with other stops even if one fails
            }
        }
        
        await MainActor.run {
            self.stopLocations = locations
        }
    }
    
    private func updateMapRegion() {
        guard !stopLocations.isEmpty else { return }
        
        // Calculate the center and span to fit all stops
        let latitudes = stopLocations.map { $0.coordinate.latitude }
        let longitudes = stopLocations.map { $0.coordinate.longitude }
        
        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else {
            return
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Add some padding to the span
        let latDelta = max(0.02, (maxLat - minLat) * 1.5)
        let lonDelta = max(0.02, (maxLon - minLon) * 1.5)
        
        let span = MKCoordinateSpan(
            latitudeDelta: latDelta,
            longitudeDelta: lonDelta
        )
        
        self.mapRegion = MKCoordinateRegion(center: center, span: span)
    }
}

struct RouteStopRow: View {
    let stop: RouteStop
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(stop.stopSequence)")
                .font(.headline)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.stopName)
                    .font(.headline)
                
                Text("ID: \(stop.stopId)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct RouteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RouteDetailView(routeId: "C1", routeName: "Sample Route")
    }
} 