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
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Station selection (moved to top, no header)
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            ModernStationSelector(
                                departureStationName: $departureStationName,
                                arrivalStationName: $arrivalStationName,
                                onSelectDeparture: {
                                    stationSearchType = .departure
                                    showingStationSearch.toggle()
                                },
                                onSelectArrival: {
                                    stationSearchType = .arrival
                                    showingStationSearch.toggle()
                                },
                                onSwapStations: swapStations
                            )
                            
                            // Smaller search button
                            ModernSearchButton(
                                isLoading: isLoading,
                                isEnabled: !departureStationId.isEmpty && !arrivalStationId.isEmpty,
                                action: {
                                    saveLastSelection()
                                    loadNextTrain(useCache: false)
                                }
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.lg)
                        
                        // Results section
                        if isLoading {
                            ModernLoadingView()
                                .padding(.vertical, DesignSystem.Spacing.xxl)
                        } else if let errorMessage = errorMessage {
                            ModernErrorView(
                                message: errorMessage,
                                onRetry: {
                                    loadNextTrain(useCache: false)
                                }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        } else if let train = nextTrain {
                            VStack(spacing: DesignSystem.Spacing.lg) {
                                // Success state header
                                HStack {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("YOUR NEXT TRAIN")
                                            .font(DesignSystem.Typography.captionMono)
                                            .foregroundColor(DesignSystem.Colors.textTertiary)
                                        
                                        Text("Ready to go")
                                            .font(DesignSystem.Typography.headingSmall)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Live indicator
                                    HStack(spacing: DesignSystem.Spacing.xs) {
                                        Circle()
                                            .fill(DesignSystem.Colors.success)
                                            .frame(width: 8, height: 8)
                                            .scaleEffect(1.0)
                                            .animation(
                                                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                                value: UUID()
                                            )
                                        
                                        Text("LIVE")
                                            .font(DesignSystem.Typography.captionMono)
                                            .foregroundColor(DesignSystem.Colors.success)
                                            .fontWeight(.bold)
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                
                                // Train card
                                ModernTrainCard(
                                    train: train,
                                    departureStation: departureStationName,
                                    arrivalStation: arrivalStationName,
                                    isNextTrain: true
                                )
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                            }
                        } else if !departureStationName.isEmpty && !arrivalStationName.isEmpty {
                            ModernEmptyView()
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
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
    
    private func swapStations() {
        let tempId = departureStationId
        let tempName = departureStationName
        
        departureStationId = arrivalStationId
        departureStationName = arrivalStationName
        arrivalStationId = tempId
        arrivalStationName = tempName
        
        // If we have a current result, refresh it
        if nextTrain != nil {
            loadNextTrain(useCache: false)
        }
    }
    
    private func saveLastSelection() {
        lastDepartureId = departureStationId
        lastDepartureName = departureStationName
        lastArrivalId = arrivalStationId
        lastArrivalName = arrivalStationName
    }
    
    private func loadDefaultStationsIfAvailable() {
        if let defaultStations = UserPreferencesService.shared.getDefaultStations() {
            departureStationId = defaultStations.departureStationId
            departureStationName = defaultStations.departureStationName
            arrivalStationId = defaultStations.arrivalStationId
            arrivalStationName = defaultStations.arrivalStationName
            
            saveLastSelection()
            loadNextTrain(useCache: true)
        }
    }
    
    private func loadNextTrain(useCache: Bool = true) {
        guard !departureStationName.isEmpty && !arrivalStationName.isEmpty else { return }
        
        if departureStationId == arrivalStationId {
            self.errorMessage = "Please select different stations for departure and arrival"
            return
        }
        
        let cacheKey = cacheService.nextTrainCacheKey(
            departure: departureStationName,
            arrival: arrivalStationName
        )
        
        if useCache,
           let cachedTrain = cacheService.nextTrainCache[cacheKey],
           cacheService.isCacheValid(lastUpdated: cacheService.nextTrainLastUpdated[cacheKey]) {
            self.nextTrain = cachedTrain
            return
        }
        
        Task {
            await loadNextTrainFromAPI()
        }
    }
    
    private func loadNextTrainFromAPI() async {
        isLoading = true
        errorMessage = nil
        
        let cacheKey = cacheService.nextTrainCacheKey(
            departure: departureStationName,
            arrival: arrivalStationName
        )
        
        do {
            let response = try await apiService.fetchNextTrain(
                departureStation: departureStationName,
                arrivalStation: arrivalStationName
            )
            
            await MainActor.run {
                isLoading = false
                nextTrain = response.nextTrain
                
                cacheService.nextTrainCache[cacheKey] = response.nextTrain
                cacheService.nextTrainLastUpdated[cacheKey] = Date()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Unable to find the next train"
                nextTrain = nil
            }
        }
    }
}

// MARK: - Supporting Views

struct ModernSearchButton: View {
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(isLoading ? "Searching..." : "Find Next Train")
                    .font(DesignSystem.Typography.bodySmall)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                    .fill(
                        isEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: isPressed)
        }
        .disabled(!isEnabled || isLoading)
        .pressEvents {
            withAnimation(DesignSystem.Animation.quick) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(DesignSystem.Animation.quick) {
                isPressed = false
            }
        }
    }
}

struct ModernLoadingView: View {
    @State private var rotation = 0.0
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.border, lineWidth: 3)
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(DesignSystem.Colors.primary, lineWidth: 3)
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(rotation))
                    .animation(
                        Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: rotation
                    )
            }
            .onAppear {
                rotation = 360
            }
            
            Text("Finding your train...")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct ModernErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.warning)
                
                Text("Something went wrong")
                    .font(DesignSystem.Typography.headingSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(message)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onRetry) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    Text("Try Again")
                        .font(DesignSystem.Typography.bodyMedium)
                        .fontWeight(.medium)
                }
            }
            .secondaryButtonStyle()
        }
        .padding(DesignSystem.Spacing.xl)
        .cardStyle()
    }
}

struct ModernEmptyView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "train.side.front.car")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Ready to search")
                    .font(DesignSystem.Typography.headingSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Tap the search button to find your next train")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .cardStyle()
    }
}

struct NextTrainView_Previews: PreviewProvider {
    static var previews: some View {
        NextTrainView()
    }
}
