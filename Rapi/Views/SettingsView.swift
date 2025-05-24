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
    
    @AppStorage("averageTimeToStation") var averageTimeToStation: Int = 15
    @AppStorage("themeSetting") private var themeSetting: ThemeSetting = .system
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Text("Settings")
                                .font(DesignSystem.Typography.displayMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .fontWeight(.bold)
                            
                            Text("Customize your journey")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.top, DesignSystem.Spacing.lg)
                        
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            // Default Route Section
                            ModernSettingsSection(
                                title: "Default Route",
                                subtitle: "Set your most frequent journey for quick access"
                            ) {
                                VStack(spacing: DesignSystem.Spacing.sm) {
                                    ModernStationButton(
                                        stationName: departureStationName,
                                        placeholder: "Departure",
                                        type: .departure,
                                        action: {
                                            stationSearchType = .departure
                                            showingStationSearch.toggle()
                                        }
                                    )
                                    
                                    ModernStationButton(
                                        stationName: arrivalStationName,
                                        placeholder: "Arrival",
                                        type: .arrival,
                                        action: {
                                            stationSearchType = .arrival
                                            showingStationSearch.toggle()
                                        }
                                    )
                                    
                                    // Action buttons
                                    HStack(spacing: DesignSystem.Spacing.sm) {
                                        if hasDefaultStations {
                                            Button(action: clearDefaultStations) {
                                                HStack(spacing: DesignSystem.Spacing.xs) {
                                                    Image(systemName: "trash")
                                                        .font(.system(size: 14, weight: .medium))
                                                    Text("Clear")
                                                        .font(DesignSystem.Typography.bodySmall)
                                                        .fontWeight(.medium)
                                                }
                                                .foregroundColor(DesignSystem.Colors.error)
                                                .padding(.horizontal, DesignSystem.Spacing.md)
                                                .padding(.vertical, DesignSystem.Spacing.sm)
                                                .background(
                                                    RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                                        .fill(DesignSystem.Colors.surfaceElevated)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                                                .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
                                                        )
                                                )
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: saveDefaultStations) {
                                            HStack(spacing: DesignSystem.Spacing.xs) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .medium))
                                                Text("Save Route")
                                                    .font(DesignSystem.Typography.bodySmall)
                                                    .fontWeight(.medium)
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, DesignSystem.Spacing.md)
                                            .padding(.vertical, DesignSystem.Spacing.sm)
                                            .background(
                                                RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                                    .fill(
                                                        (departureStationId.isEmpty || arrivalStationId.isEmpty) ?
                                                        DesignSystem.Colors.textTertiary :
                                                        DesignSystem.Colors.success
                                                    )
                                            )
                                        }
                                        .disabled(departureStationId.isEmpty || arrivalStationId.isEmpty)
                                    }
                                    .padding(.top, DesignSystem.Spacing.sm)
                                }
                            }
                            
                            // Travel Time Section
                            ModernSettingsSection(
                                title: "Travel Time",
                                subtitle: "How long does it take you to reach the station?"
                            ) {
                                ModernSliderControl(
                                    value: $averageTimeToStation,
                                    range: 0...120,
                                    step: 5,
                                    unit: "min",
                                    label: "Time to station"
                                )
                            }
                            
                            // Appearance Section
                            ModernSettingsSection(
                                title: "Appearance",
                                subtitle: "Choose your preferred theme"
                            ) {
                                ModernThemePicker(selectedTheme: $themeSetting)
                            }
                            
                            // API Tools Section
                            ModernSettingsSection(
                                title: "Explore",
                                subtitle: "Browse all available data"
                            ) {
                                VStack(spacing: DesignSystem.Spacing.xs) {
                                    ModernNavigationRow(
                                        icon: "list.bullet",
                                        title: "All Stations",
                                        subtitle: "Browse complete station list",
                                        destination: AnyView(StationListView())
                                    )
                                    
                                    ModernNavigationRow(
                                        icon: "train.side.front.car",
                                        title: "All Routes",
                                        subtitle: "Explore train routes",
                                        destination: AnyView(RouteListView())
                                    )
                                }
                            }
                            
                            // About Section
                            ModernSettingsSection(
                                title: "About",
                                subtitle: "App information"
                            ) {
                                VStack(spacing: DesignSystem.Spacing.sm) {
                                    ModernInfoRow(label: "App Version", value: "1.0.0")
                                    ModernInfoRow(label: "API Source", value: "Renfe Cercanías")
                                    ModernInfoRow(label: "Status", value: "Unofficial")
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        
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
            .alert(isPresented: $showSavedAlert) {
                Alert(
                    title: Text("Route Saved"),
                    message: Text("Your default route has been saved successfully."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func loadDefaultStationsIfAvailable() {
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
        
        departureStationId = ""
        departureStationName = ""
        arrivalStationId = ""
        arrivalStationName = ""
        hasDefaultStations = false
    }
}

// MARK: - Supporting Views

struct ModernSettingsSection<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title.uppercased())
                    .font(DesignSystem.Typography.captionMono)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            content
                .padding(DesignSystem.Spacing.lg)
                .cardStyle()
        }
    }
}

struct ModernSliderControl: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    let label: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label.uppercased())
                        .font(DesignSystem.Typography.captionMono)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text("\(value) \(unit)")
                        .font(DesignSystem.Typography.monoLarge)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fontWeight(.bold)
                }
                
                Spacer()
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                Button(action: { 
                    if value > range.lowerBound {
                        value = max(range.lowerBound, value - step)
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(DesignSystem.Colors.surfaceElevated)
                                .overlay(
                                    Circle()
                                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                )
                        )
                }
                .disabled(value <= range.lowerBound)
                
                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { value = Int($0) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: Double(step)
                )
                .accentColor(DesignSystem.Colors.primary)
                
                Button(action: { 
                    if value < range.upperBound {
                        value = min(range.upperBound, value + step)
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(DesignSystem.Colors.surfaceElevated)
                                .overlay(
                                    Circle()
                                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                )
                        )
                }
                .disabled(value >= range.upperBound)
            }
        }
    }
}

struct ModernThemePicker: View {
    @Binding var selectedTheme: ThemeSetting
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(ThemeSetting.allCases) { theme in
                ModernThemeOption(
                    theme: theme,
                    isSelected: selectedTheme == theme,
                    onSelect: { selectedTheme = theme }
                )
            }
        }
    }
}

struct ModernThemeOption: View {
    let theme: ThemeSetting
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: theme.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fontWeight(.medium)
                    
                    Text(theme.description)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                } else {
                    Circle()
                        .stroke(DesignSystem.Colors.border, lineWidth: 2)
                        .frame(width: 18, height: 18)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                            .stroke(
                                isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
    }
}

struct ModernNavigationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.monoMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .fontWeight(.medium)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

// MARK: - ThemeSetting Extensions
extension ThemeSetting {
    var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
    
    var description: String {
        switch self {
        case .system: return "Follow system settings"
        case .light: return "Always use light mode"
        case .dark: return "Always use dark mode"
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 
