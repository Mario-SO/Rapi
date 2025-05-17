import SwiftUI

struct StationSearchView: View {
    @Environment(\.dismiss) var dismiss // Use dismiss environment value
    @Binding var selectedStationId: String // Pass back ID
    @Binding var selectedStationName: String // Pass back Name for display
    var searchType: StationSearchType // To customize title

    @State private var searchText: String = ""
    @State private var stations: [StationApiModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Use API service instead of mock
    private let apiService = APIService.shared
    
    // Filter in-memory stations
    var filteredStations: [StationApiModel] {
        if searchText.isEmpty {
            return stations
        } else {
            return stations.filter { $0.stopName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading stations...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Text("Error loading stations")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            loadStations()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else {
                    List(filteredStations) { station in
                        Button(action: {
                            selectedStationId = station.id
                            selectedStationName = station.stopName
                            dismiss() // Use dismiss action
                        }) {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                Text(station.stopName)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .overlay(
                        Group {
                            if filteredStations.isEmpty && !searchText.isEmpty {
                                Text("No stations found matching '\(searchText)'")
                                    .foregroundColor(.gray)
                            } else if filteredStations.isEmpty {
                                Text("No stations available")
                                    .foregroundColor(.gray)
                            }
                        }
                    )
                }
            }
            .searchable(text: $searchText, prompt: "Search for a station")
            .navigationTitle(searchType == .departure ? "Departure Station" : "Arrival Station")
            .toolbar { // Use .toolbar for navigation bar items
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss() // Use dismiss action
                    }
                }
            }
            .onAppear {
                if stations.isEmpty {
                    loadStations()
                }
            }
            .onChange(of: searchText) { oldValue, newValue in
                if newValue.count >= 3 {
                    // Only search API when at least 3 characters entered
                    searchStations(query: newValue)
                }
            }
        }
    }
    
    // Load all stations from API
    private func loadStations() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedStations = try await apiService.fetchAllStations()
                await MainActor.run {
                    stations = fetchedStations
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load stations: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    // Search stations with query
    private func searchStations(query: String) {
        guard query.count >= 3 else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let searchResults = try await apiService.fetchAllStations(searchQuery: query)
                await MainActor.run {
                    stations = searchResults
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to search stations: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct StationSearchView_Previews: PreviewProvider {
    @State static var previewStationId: String = ""
    @State static var previewStationName: String = ""
    @State static var isPresented = true // Not used directly by this preview, but for context

    static var previews: some View {
        StationSearchView(
            selectedStationId: $previewStationId,
            selectedStationName: $previewStationName,
            searchType: .departure
        )
    }
} 