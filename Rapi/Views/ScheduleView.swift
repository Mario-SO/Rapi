import SwiftUI

struct ScheduleView: View {
    // Get stations from NextTrainView's last selection
    @AppStorage("lastSelectedDepartureId") var departureStationId: String = ""
    @AppStorage("lastSelectedDepartureName") var departureStationName: String = ""
    @AppStorage("lastSelectedArrivalId") var arrivalStationId: String = ""
    @AppStorage("lastSelectedArrivalName") var arrivalStationName: String = ""
    
    @State private var selectedDate = Date()
    @State private var isLoading = false
    @State private var timetable: [Train] = []
    @State private var errorMessage: String?
    @State private var isRefreshing = false
    
    // For elegant date selector - now using an index instead of boolean
    @State private var selectedDateIndex = 0
    
    // Access the shared cache service
    @StateObject private var cacheService = DataCacheService.shared
    
    // API service
    private let apiService = APIService.shared
    
    // Date formatter for display
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }()
    
    // Date formatter for API requests
    private let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private var nextTrainId: String? {
        let now = Date()
        let calendar = Calendar.current

        // Only proceed to find a "next train" if the selectedDate is today.
        guard calendar.isDate(selectedDate, inSameDayAs: now) else {
            return nil // No highlight for past or future days.
        }

        // If we are here, selectedDate is today. Now find the next upcoming train.
        for train in timetable {
            // Ensure we use selectedDate (which is confirmed to be today) for generating the full DateTime.
            if let departureFullDateTime = train.departureDateTime(on: selectedDate) {
                if departureFullDateTime >= now { // Find the first train from now onwards.
                    return train.id
                }
            }
        }
        return nil // No suitable upcoming train found for today, or timetable is empty.
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                if departureStationName.isEmpty || arrivalStationName.isEmpty {
                    // No stations selected
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                            .padding(.bottom, 4)
                        
                        Text("Select stations in the Next Train tab")
                            .font(.headline)
                        
                        Text("The schedule will show all trains for your selected route")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                    .padding()
                } else if departureStationId == arrivalStationId {
                    // Same station selected error
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 30))
                            .foregroundColor(.orange)
                            .padding(.bottom, 4)
                        
                        Text("Cannot show schedule")
                            .font(.headline)
                        
                        Text("Please select different stations for departure and arrival in the Next Train tab")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Compact header with route info
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                // Route display with chip style
                                HStack(spacing: 8) {
                                    Text(departureStationName)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text(arrivalStationName)
                                        .font(.headline)
                                        .lineLimit(1)
                                }
                                
                                // Elegant date selector
                                DateSelectorView(
                                    selectedDateIndex: $selectedDateIndex, 
                                    onDateChanged: { newDate in
                                        selectedDate = newDate
                                        loadSchedule()
                                    }
                                )
                                .padding(.top, 8)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                        .background(Color(.systemBackground))
                        
                        Divider()
                        
                        if isLoading && !isRefreshing {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        } else if let errorMessage = errorMessage {
                            Spacer()
                            Text(errorMessage)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                        } else if timetable.isEmpty {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "train.side.front.car")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                                Text("No trains found for this date")
                                    .font(.headline)
                                Text("Try selecting a different date")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            Spacer()
                        } else {
                            // Schedule header
                            HStack {
                                Text(dateFormatter.string(from: selectedDate))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(timetable.count) trains")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            
                            // // Add a manual refresh button for clarity
                            // Button {
                            //     Task {
                            //         await refreshSchedule()
                            //     }
                            // } label: {
                            //     Label("Refresh Schedule", systemImage: "arrow.clockwise")
                            //         .font(.footnote)
                            //         .foregroundColor(.blue)
                            // }
                            // .padding(.horizontal)
                            // .padding(.bottom, 8)
                            
                            // Schedule list with pull-to-refresh (kept for convenience)
                            List {
                                ForEach(timetable) { train in
                                    MinimalTrainRow(train: train, isNextTrain: train.id == nextTrainId)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                                        .padding(.horizontal)
                                }
                                
                                // Add spacer at the bottom to prevent the tab bar from covering items
                                Color.clear
                                    .frame(height: 100)
                                    .listRowSeparator(.hidden)
                            }
                            .listStyle(PlainListStyle())
                            .refreshable {
                                await refreshSchedule()
                            }
                        }
                    }
                    .onAppear {
                        loadSchedule(useCache: true)
                    }
                }
            }
            .navigationTitle("Schedule")
        }
    }
    
    // Check if two dates are on the same day
    private func isSameDay(date1: Date, date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    // Check if a date is tomorrow
    private func isTomorrow(date: Date) -> Bool {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Calendar.current.isDate(date, inSameDayAs: tomorrow)
    }
    
    // Refreshes data by forcing a network call
    private func refreshSchedule() async {
        // Set refreshing state to avoid showing spinner in the center
        isRefreshing = true
        await loadScheduleFromAPI()
        isRefreshing = false
    }
    
    private func loadSchedule(useCache: Bool = true) {
        guard !departureStationName.isEmpty && !arrivalStationName.isEmpty else { return }
        
        // Format the date for the API and cache key
        let dateString = apiDateFormatter.string(from: selectedDate)
        let cacheKey = cacheService.timetableCacheKey(
            departure: departureStationName,
            arrival: arrivalStationName,
            date: dateString
        )
        
        // Check if we have valid cached data
        if useCache, 
           let cachedTimetable = cacheService.timetableCache[cacheKey],
           cacheService.isCacheValid(lastUpdated: cacheService.timetableLastUpdated[cacheKey]) {
            // Use cached data
            self.timetable = cachedTimetable
            errorMessage = cachedTimetable.isEmpty ? "No trains found for this route on the selected date." : nil
            return
        }
        
        // If no valid cache, load from API
        Task {
            await loadScheduleFromAPI()
        }
    }
    
    private func loadScheduleFromAPI() async {
        // Don't set isLoading if we're just refreshing
        if !isRefreshing {
            isLoading = true
        }
        
        errorMessage = nil
        
        // Format the date for the API and cache key
        let dateString = apiDateFormatter.string(from: selectedDate)
        let cacheKey = cacheService.timetableCacheKey(
            departure: departureStationName,
            arrival: arrivalStationName,
            date: dateString
        )
        
        do {
            let response = try await apiService.fetchTimetable(
                departureStation: departureStationName,
                arrivalStation: arrivalStationName,
                date: dateString
            )
            
            // Update UI on main thread
            await MainActor.run {
                isLoading = false
                var fetchedTimetable = response.timetable
                
                // Sort the timetable by departure time
                fetchedTimetable.sort { train1, train2 in
                    guard let dt1 = train1.departureDateTime(on: self.selectedDate),
                          let dt2 = train2.departureDateTime(on: self.selectedDate) else {
                        return train1.departureDateTime(on: self.selectedDate) != nil
                    }
                    return dt1 < dt2
                }
                
                // Update the cache
                cacheService.timetableCache[cacheKey] = fetchedTimetable
                cacheService.timetableLastUpdated[cacheKey] = Date()
                
                // Update the view
                self.timetable = fetchedTimetable
                
                if self.timetable.isEmpty {
                    errorMessage = "No trains found for this route on the selected date."
                }
            }
        } catch {
            // Handle error on main thread
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load the schedule: \(error.localizedDescription)"
                timetable = []
            }
        }
    }
}

struct DateSelectorView: View {
    @Binding var selectedDateIndex: Int
    var onDateChanged: (Date) -> Void
    
    private let today = Date()
    private let dates: [Date]
    
    // Day name formatter
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    // Day number formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    init(selectedDateIndex: Binding<Int>, onDateChanged: @escaping (Date) -> Void) {
        self._selectedDateIndex = selectedDateIndex
        self.onDateChanged = onDateChanged
        
        // Initialize 5 dates (today + 4 future days)
        var dateArray: [Date] = []
        let calendar = Calendar.current
        
        for dayOffset in 0..<5 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                dateArray.append(date)
            }
        }
        
        self.dates = dateArray
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(0..<dates.count, id: \.self) { index in
                    let date = dates[index]
                    let isToday = index == 0
                    let isTomorrow = index == 1
                    
                    DateCard(
                        isSelected: selectedDateIndex == index,
                        dayName: dayFormatter.string(from: date),
                        dayNumber: dateFormatter.string(from: date),
                        isToday: isToday,
                        isTomorrow: isTomorrow,
                        width: geometry.size.width / CGFloat(dates.count)
                    )
                    .onTapGesture {
                        if selectedDateIndex != index {
                            selectedDateIndex = index
                            onDateChanged(date)
                        }
                    }
                }
            }
        }
        .frame(height: 80) // Fixed height for the date selector
    }
}

struct DateCard: View {
    let isSelected: Bool
    let dayName: String
    let dayNumber: String
    let isToday: Bool
    let isTomorrow: Bool
    let width: CGFloat
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayName)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(dayNumber)
                .font(.title3)
                .fontWeight(.bold)
                .frame(width: 42, height: 28)  // Increased width to accommodate padding
                .padding(.horizontal, 6)  // Add horizontal padding inside the pill
                .background(isSelected ? Color.blue : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())  // Changed from Circle to Capsule
            
            if isToday {
                Text("Today")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            } else if isTomorrow {
                Text("Tomorrow")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .blue : .secondary)
            } else {
                // For days after tomorrow, provide an empty space to maintain consistent height
                Text(" ")
                    .font(.caption2)
            }
        }
        .frame(width: width)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.clear))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke( Color.clear, lineWidth: 2)
                )
                .padding(.horizontal, 2) // Add small padding between cards
        )
    }
}

struct MinimalTrainRow: View {
    let train: Train
    let isNextTrain: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Route label
            Text(train.routeShortName)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .frame(width: 30)
            
            // Time and stations
            HStack(spacing: 12) {
                // Departure time
                Text(train.formattedDepartureTime)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(isNextTrain ? .bold : .medium)
                
                // Simple connection line
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                
                // Arrival time
                Text(train.formattedArrivalTime)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                // Duration
                Text("\(train.durationInMinutes)m")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(isNextTrain ? Color.accentColor.opacity(0.15) : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            HStack {
                if isNextTrain {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 4)
                        .cornerRadius(2)
                }
                Spacer()
            }
        )
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}
