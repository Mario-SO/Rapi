import Foundation
import SwiftUI

// This class will hold cached data and provide refresh functionality
class DataCacheService: ObservableObject {
    static let shared = DataCacheService()
    
    // Schedule data cache
    @Published var timetableCache: [String: [Train]] = [:]
    @Published var timetableLastUpdated: [String: Date] = [:]
    
    // Next train data cache
    @Published var nextTrainCache: [String: Train] = [:]
    @Published var nextTrainLastUpdated: [String: Date] = [:]
    
    // Default cache duration: 30 minutes
    private let defaultCacheDuration: TimeInterval = 30 * 60
    
    private init() {}
    
    // Generate a unique key for timetable cache based on route and date
    func timetableCacheKey(departure: String, arrival: String, date: String) -> String {
        // Safety checks - sanitize inputs
        let safeDeparture = departure.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeArrival = arrival.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeDate = date.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !safeDeparture.isEmpty, !safeArrival.isEmpty, !safeDate.isEmpty else {
            // Return an impossible key that won't match any cache entry
            return "invalid_key_\(UUID().uuidString)"
        }
        
        return "\(safeDeparture)_\(safeArrival)_\(safeDate)"
    }
    
    // Generate a unique key for next train cache based on route
    func nextTrainCacheKey(departure: String, arrival: String) -> String {
        // Safety checks - sanitize inputs
        let safeDeparture = departure.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeArrival = arrival.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !safeDeparture.isEmpty, !safeArrival.isEmpty else {
            // Return an impossible key that won't match any cache entry
            return "invalid_key_\(UUID().uuidString)"
        }
        
        return "\(safeDeparture)_\(safeArrival)"
    }
    
    // Add timetable to cache
    func cacheTimetable(departure: String, arrival: String, date: String, timetable: [Train]) {
        let key = timetableCacheKey(departure: departure, arrival: arrival, date: date)
        timetableCache[key] = timetable
        timetableLastUpdated[key] = Date()
        
        // Clean up old cache entries
        cleanupCaches()
    }
    
    // Add next train to cache
    func cacheNextTrain(departure: String, arrival: String, train: Train) {
        let key = nextTrainCacheKey(departure: departure, arrival: arrival)
        nextTrainCache[key] = train
        nextTrainLastUpdated[key] = Date()
        
        // Clean up old cache entries
        cleanupCaches()
    }
    
    // Clear all cached data
    func clearAllCaches() {
        timetableCache.removeAll()
        timetableLastUpdated.removeAll()
        nextTrainCache.removeAll()
        nextTrainLastUpdated.removeAll()
    }
    
    // Clear caches for specific route
    func clearCacheForRoute(departure: String, arrival: String) {
        // Clear NextTrain cache
        let nextTrainKey = nextTrainCacheKey(departure: departure, arrival: arrival)
        nextTrainCache.removeValue(forKey: nextTrainKey)
        nextTrainLastUpdated.removeValue(forKey: nextTrainKey)
        
        // Clear Timetable caches (find all keys for this route with different dates)
        let routePrefix = "\(departure)_\(arrival)_"
        let keysToRemove = timetableCache.keys.filter { $0.hasPrefix(routePrefix) }
        
        for key in keysToRemove {
            timetableCache.removeValue(forKey: key)
            timetableLastUpdated.removeValue(forKey: key)
        }
    }
    
    // Check if cache exists and is not too old
    func isCacheValid(lastUpdated: Date?, maxAge: TimeInterval = 0) -> Bool {
        guard let lastUpdated = lastUpdated else {
            return false
        }
        
        // Use the provided maxAge or default to 30 minutes
        let cacheAge = maxAge > 0 ? maxAge : defaultCacheDuration
        return Date().timeIntervalSince(lastUpdated) < cacheAge
    }
    
    // Clean up expired caches to avoid memory bloat
    private func cleanupCaches() {
        // Clean up old timetable caches (older than 1 day)
        let oldTimetableKeys = timetableLastUpdated.filter { 
            Date().timeIntervalSince($0.value) > 24 * 60 * 60
        }.keys
        
        for key in oldTimetableKeys {
            timetableCache.removeValue(forKey: key)
            timetableLastUpdated.removeValue(forKey: key)
        }
        
        // Clean up old next train caches (older than 2 hours)
        let oldNextTrainKeys = nextTrainLastUpdated.filter { 
            Date().timeIntervalSince($0.value) > 2 * 60 * 60
        }.keys
        
        for key in oldNextTrainKeys {
            nextTrainCache.removeValue(forKey: key)
            nextTrainLastUpdated.removeValue(forKey: key)
        }
    }
} 