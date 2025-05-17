import SwiftUI
import MapKit

struct StationDetailView: View {
    let station: StationApiModel
    @State private var departures: [DepartureModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // API service
    private let apiService = APIService.shared
    
    // For the map
    @State private var region: MKCoordinateRegion
    
    init(station: StationApiModel) {
        self.station = station
        
        // Initialize the map region centered on the station
        let latitude = Double(station.stopLat) ?? 0.0
        let longitude = Double(station.stopLon) ?? 0.0
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        _region = State(initialValue: initialRegion)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Station name
                Text(station.stopName)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // Station ID
                Text("Station ID: \(station.stopId)")
                    .padding(.horizontal)
                
//                // Coordinates
//                HStack {
//                    Text("Coordinates:")
//                        .font(.headline)
//                    Spacer()
//                    Text("\(station.stopLat), \(station.stopLon)")
//                        .font(.body)
//                }
//                .padding(.horizontal)
                
                // Map view
                Map(initialPosition: .region(region)) {
                    Marker(station.stopName, coordinate: CLLocationCoordinate2D(latitude: Double(station.stopLat) ?? 0.0, longitude: Double(station.stopLon) ?? 0.0))
                        .tint(.blue)
                }
                .frame(height: 200)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Departures section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Departures")
                        .font(.title2)
                        .padding(.top, 20)
                        .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView("Loading departures...")
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 8) {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                loadDepartures()
                            } label: {
                                Text("Retry")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    } else if departures.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "train.side.front.car")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                                .padding(.bottom, 8)
                            
                            Text("No departures available")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(departures) { departure in
                                DepartureRow(departure: departure)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            }
                            Color.clear
                                .frame(height: 90)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Station Details")
        .navigationBarTitleDisplayMode(.inline) // Reduces space taken by title
        .onAppear {
            loadDepartures()
        }
    }
    
    private func loadDepartures() {
        isLoading = true
        errorMessage = nil
        
        // Get the current date and time formatted for the API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let currentTime = timeFormatter.string(from: Date())
        
        Task {
            do {
                let response = try await apiService.fetchStationDepartures(
                    stationId: station.stopId,
                    date: currentDate,
                    time: currentTime
                )
                
                await MainActor.run {
                    departures = response.departures
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load departures: \(error.localizedDescription)"
                    isLoading = false
                    
                    // Print details for debugging
                    print("Error loading departures: \(error)")
                }
            }
        }
    }
}

// Departure row for the list
struct DepartureRow: View {
    let departure: DepartureModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(departure.routeShortName)
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                Text(departure.tripHeadsign.isEmpty ? "No Destination" : departure.tripHeadsign)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(departure.formattedDepartureTime)
                .font(.title3)
                .fontWeight(.bold)
        }
    }
} 
