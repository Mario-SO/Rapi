import SwiftUI

struct ModernStationSelector: View {
    @Binding var departureStationName: String
    @Binding var arrivalStationName: String
    let onSelectDeparture: () -> Void
    let onSelectArrival: () -> Void
    let onSwapStations: () -> Void
    
    @State private var isSwapping = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Departure station
            ModernStationButton(
                stationName: departureStationName,
                placeholder: "From",
                type: .departure,
                action: onSelectDeparture
            )
            
            // Swap button in the middle
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(DesignSystem.Animation.bounce) {
                        isSwapping = true
                        onSwapStations()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isSwapping = false
                    }
                }) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(DesignSystem.Colors.surfaceElevated)
                                .overlay(
                                    Circle()
                                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                )
                        )
                }
                .rotationEffect(.degrees(isSwapping ? 180 : 0))
                .scaleEffect(isSwapping ? 1.1 : 1.0)
                .animation(DesignSystem.Animation.bounce, value: isSwapping)
                
                Spacer()
            }
            .zIndex(1) // Ensure it appears above the station buttons
            .offset(y: -DesignSystem.Spacing.sm) // Slight overlap with buttons
            
            // Arrival station
            ModernStationButton(
                stationName: arrivalStationName,
                placeholder: "To",
                type: .arrival,
                action: onSelectArrival
            )
            .offset(y: -DesignSystem.Spacing.sm) // Slight overlap to account for swap button
        }
    }
}

struct ModernStationButton: View {
    let stationName: String
    let placeholder: String
    let type: StationButtonType
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum StationButtonType {
        case departure, arrival
        
        var icon: String {
            switch self {
            case .departure: return "circle.fill"
            case .arrival: return "location.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .departure: return DesignSystem.Colors.primary
            case .arrival: return DesignSystem.Colors.accent
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Station icon
                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(type.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Label
                    Text(placeholder.uppercased())
                        .font(DesignSystem.Typography.captionMono)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    // Station name or placeholder
                    if stationName.isEmpty {
                        Text("Select station")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    } else {
                        Text(stationName)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .fill(DesignSystem.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                            .stroke(
                                isPressed ? type.color : DesignSystem.Colors.border,
                                lineWidth: isPressed ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: isPressed)
        }
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

// Custom press event modifier
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
} 