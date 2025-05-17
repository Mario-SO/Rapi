import SwiftUI

// ThemeSetting enum moved to Models/ThemeSetting.swift

struct SettingsView: View {
    @State private var departureStationId: String = ""
    @State private var departureStationName: String = ""
    @State private var arrivalStationId: String = ""
    @State private var arrivalStationName: String = ""
    
    @State private var showingStationSearch = false
    @State private var stationSearchType: StationSearchType = .departure
    
    @State private var hasDefaultStations = false
    @State private var showSavedAlert = false
    
    @AppStorage("averageTimeToStation") var averageTimeToStation: Int = 15 // Default to 15 minutes
    @AppStorage("themeSetting") private var themeSetting: ThemeSetting = .system
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Default Route")) {
                    Text("Set your default stations to quickly see your most frequent route when opening the app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        stationSearchType = .departure
                        showingStationSearch.toggle()
                    }) {
                        HStack {
                            Text("Default Departure Station")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(departureStationName.isEmpty ? "None" : departureStationName)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        stationSearchType = .arrival
                        showingStationSearch.toggle()
                    }) {
                        HStack {
                            Text("Default Arrival Station")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(arrivalStationName.isEmpty ? "None" : arrivalStationName)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    Button(action: saveDefaultStations) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Save Default Route")
                        }
                    }
                    .disabled(departureStationId.isEmpty || arrivalStationId.isEmpty)
                    
                    if hasDefaultStations {
                        Button(action: clearDefaultStations) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Clear Default Route")
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Commute Time")) {
                    Text("Set the average time it takes you to get to the station. This will be used to calculate when you should leave.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    
                    HStack {
                        Text("Time to station")
                        Spacer()
                        Text("\(averageTimeToStation) min")
                            .frame(minWidth: 50)
                            .foregroundColor(.blue)
                        Spacer()
                        Stepper("", value: $averageTimeToStation, in: 0...120, step: 5)
                            .labelsHidden()
                    }
                }
                
                Section(header: Text("API Tools")) {
                    NavigationLink(destination: StationListView()) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.blue)
                            Text("All Stations")
                        }
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $themeSetting) {
                        ForEach(ThemeSetting.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Renfe Cercanías API")
                        Spacer()
                        Text("Unofficial")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .background(Color(.systemGroupedBackground))
            .onAppear(perform: loadDefaultStationsIfAvailable)
            .sheet(isPresented: $showingStationSearch) {
                StationSearchView(
                    selectedStationId: stationSearchType == .departure ? $departureStationId : $arrivalStationId,
                    selectedStationName: stationSearchType == .departure ? $departureStationName : $arrivalStationName,
                    searchType: stationSearchType
                )
            }
            .alert(isPresented: $showSavedAlert) {
                Alert(
                    title: Text("Default Route Saved"),
                    message: Text("Your default route has been saved."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 90)
            }
        }
    }
    
    private func loadDefaultStationsIfAvailable() {
        // Check if default stations are already set
        if let defaultStations = UserPreferencesService.shared.getDefaultStations() {
            departureStationId = defaultStations.departureStationId
            departureStationName = defaultStations.departureStationName
            arrivalStationId = defaultStations.arrivalStationId
            arrivalStationName = defaultStations.arrivalStationName
            hasDefaultStations = true
        } else {
            hasDefaultStations = false
        }
    }
    
    private func saveDefaultStations() {
        guard !departureStationId.isEmpty && !arrivalStationId.isEmpty else { return }
        
        UserPreferencesService.shared.saveDefaultStations(
            departureStationId: departureStationId,
            departureStationName: departureStationName,
            arrivalStationId: arrivalStationId,
            arrivalStationName: arrivalStationName
        )
        
        hasDefaultStations = true
        showSavedAlert = true
    }
    
    private func clearDefaultStations() {
        UserPreferencesService.shared.clearDefaultStations()
        
        // Clear local state
        departureStationId = ""
        departureStationName = ""
        arrivalStationId = ""
        arrivalStationName = ""
        hasDefaultStations = false
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 
