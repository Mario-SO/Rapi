import SwiftUI

struct NextTrainView: View {
    @State private var departureStationId: String = ""
    @State private var departureStationName: String = ""
    @State private var arrivalStationId: String = ""
    @State private var arrivalStationName: String = ""
    
    @State private var showingStationSearch = false
    @State private var stationSearchType: StationSearchType = .departure
    @State private var isLoading = false
    @State private var nextTrain: Train?
    @State private var errorMessage: String?
    
    // To share station selection with ScheduleView
    @AppStorage("lastSelectedDepartureId") var lastDepartureId: String = ""
    @AppStorage("lastSelectedDepartureName") var lastDepartureName: String = ""
    @AppStorage("lastSelectedArrivalId") var lastArrivalId: String = ""
    @AppStorage("lastSelectedArrivalName") var lastArrivalName: String = ""
    
    // Access the shared cache service
    @StateObject private var cacheService = DataCacheService.shared
    
    // API service
    private let apiService = APIService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Station selection
                    VStack(spacing: 16) {
                        StationSelectionButton(
                            stationName: $departureStationName,
                            placeholder: "Departure Station",
                            action: {
                                stationSearchType = .departure
                                showingStationSearch.toggle()
                            }
                        )
                        
                        StationSelectionButton(
                            stationName: $arrivalStationName,
                            placeholder: "Arrival Station",
                            action: {
                                stationSearchType = .arrival
                                showingStationSearch.toggle()
                            }
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Next Train button
                    Button {
                        saveLastSelection()
                        loadNextTrain(useCache: false) // Force a refresh when button is tapped
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.2.circlepath")
                            Text("Find Next Train")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(departureStationId.isEmpty || arrivalStationId.isEmpty || isLoading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Result display using the new component
                    TrainResultsDisplayView(
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        train: nextTrain,
                        departureStationName: departureStationName,
                        arrivalStationName: arrivalStationName,
                        departureStationId: departureStationId,
                        arrivalStationId: arrivalStationId
                    )
                }
                .padding(.bottom, 100) // Add extra padding at bottom to ensure scrolling
            }
            .navigationTitle("Next Train")
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .onAppear(perform: loadDefaultStationsIfAvailable)
            .sheet(isPresented: $showingStationSearch) {
                StationSearchView(
                    selectedStationId: stationSearchType == .departure ? $departureStationId : $arrivalStationId,
                    selectedStationName: stationSearchType == .departure ? $departureStationName : $arrivalStationName,
                    searchType: stationSearchType
                )
            }
        }
    }
    
    private func saveLastSelection() {
        // Save the last selected stations for ScheduleView to use
        lastDepartureId = departureStationId
        lastDepartureName = departureStationName
        lastArrivalId = arrivalStationId
        lastArrivalName = arrivalStationName
    }
    
    private func loadDefaultStationsIfAvailable() {
        // Check if we should load default stations
        if let defaultStations = UserPreferencesService.shared.getDefaultStations() {
            departureStationId = defaultStations.departureStationId
            departureStationName = defaultStations.departureStationName
            arrivalStationId = defaultStations.arrivalStationId
            arrivalStationName = defaultStations.arrivalStationName
            
            // Save these as last selection too
            saveLastSelection()
            
            // Load the next train with cache
            loadNextTrain(useCache: true)
        }
    }
    
    // Load next train with option to use cache
    private func loadNextTrain(useCache: Bool = true) {
        guard !departureStationName.isEmpty && !arrivalStationName.isEmpty else { return }
        
        // Check if the same station is selected for both departure and arrival
        if departureStationId == arrivalStationId {
            self.errorMessage = "Please select different stations for departure and arrival"
            return
        }
        
        // Generate cache key
        let cacheKey = cacheService.nextTrainCacheKey(
            departure: departureStationName,
            arrival: arrivalStationName
        )
        
        // Check if we have valid cached data
        if useCache, 
           let cachedTrain = cacheService.nextTrainCache[cacheKey],
           cacheService.isCacheValid(lastUpdated: cacheService.nextTrainLastUpdated[cacheKey]) {
            // Use cached data
            self.nextTrain = cachedTrain
            return
        }
        
        // If no valid cache, load from API
        Task {
            await loadNextTrainFromAPI()
        }
    }
    
    // Load next train data from API
    private func loadNextTrainFromAPI() async {
        isLoading = true
        errorMessage = nil
        
        // Generate cache key
        let cacheKey = cacheService.nextTrainCacheKey(
            departure: departureStationName,
            arrival: arrivalStationName
        )
        
        do {
            let response = try await apiService.fetchNextTrain(
                departureStation: departureStationName,
                arrivalStation: arrivalStationName
            )
            
            // Update UI on main thread
            await MainActor.run {
                isLoading = false
                nextTrain = response.nextTrain
                
                // Update the cache
                cacheService.nextTrainCache[cacheKey] = response.nextTrain
                cacheService.nextTrainLastUpdated[cacheKey] = Date()
            }
        } catch {
            // Handle error on main thread
            await MainActor.run {
                isLoading = false
                errorMessage = "Unable to find the next train: \(error.localizedDescription)"
                nextTrain = nil
            }
        }
    }
}

struct StationSelectionButton: View {
    @Binding var stationName: String
    let placeholder: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(stationName.isEmpty ? placeholder : stationName)
                    .foregroundColor(stationName.isEmpty ? .gray : .primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NextTrainView_Previews: PreviewProvider {
    static var previews: some View {
        NextTrainView()
    }
}
