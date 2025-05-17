import Foundation

class UserPreferencesService {
    private enum Keys {
        static let defaultStations = "userDefaultStations"
    }
    
    static let shared = UserPreferencesService()
    
    private init() {}
    
    // Save default stations for quick access
    func saveDefaultStations(departureStationId: String, departureStationName: String, 
                           arrivalStationId: String, arrivalStationName: String) {
        let stations = UserDefaultStations(
            departureStationId: departureStationId,
            departureStationName: departureStationName,
            arrivalStationId: arrivalStationId,
            arrivalStationName: arrivalStationName
        )
        
        if let encoded = try? JSONEncoder().encode(stations) {
            UserDefaults.standard.set(encoded, forKey: Keys.defaultStations)
        }
    }
    
    // Get saved default stations if they exist
    func getDefaultStations() -> UserDefaultStations? {
        guard let savedData = UserDefaults.standard.data(forKey: Keys.defaultStations),
              let stations = try? JSONDecoder().decode(UserDefaultStations.self, from: savedData) else {
            return nil
        }
        
        return stations
    }
    
    // Check if user has default stations set
    func hasDefaultStations() -> Bool {
        return UserDefaults.standard.data(forKey: Keys.defaultStations) != nil
    }
    
    // Remove default stations
    func clearDefaultStations() {
        UserDefaults.standard.removeObject(forKey: Keys.defaultStations)
    }
} 