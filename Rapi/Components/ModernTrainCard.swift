import SwiftUI

struct ModernTrainCard: View {
    let train: Train
    let departureStation: String
    let arrivalStation: String
    let isNextTrain: Bool
    @AppStorage("averageTimeToStation") var averageTimeToStation: Int = 15
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header with route badge and status
            HStack(alignment: .center) {
                // Route badge
                Text(train.routeShortName)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(isNextTrain ? DesignSystem.Colors.accent : DesignSystem.Colors.primary)
                    )
                
                Spacer()
                
                if isNextTrain {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Circle()
                            .fill(DesignSystem.Colors.accent)
                            .frame(width: 6, height: 6)
                            .scaleEffect(isPressed ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: isPressed
                            )
                        
                        Text("NEXT")
                            .font(DesignSystem.Typography.captionMono)
                            .foregroundColor(DesignSystem.Colors.accent)
                            .fontWeight(.bold)
                    }
                }
                
                // Duration
                Text("\(train.durationInMinutes) min")
                    .font(DesignSystem.Typography.monoSmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // Time display with geometric elements
            HStack {
                // Departure
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(departureStation)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                    
                    Text(train.formattedDepartureTime)
                        .font(DesignSystem.Typography.monoLarge)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Journey visualization (inspired by TE minimal graphics)
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 8, height: 8)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary,
                                    DesignSystem.Colors.primaryLight
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .frame(maxWidth: 40)
                    
                    Image(systemName: "train.side.front.car")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primaryLight,
                                    DesignSystem.Colors.primary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .frame(maxWidth: 40)
                    
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                
                // Arrival
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text(arrivalStation)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                    
                    Text(train.formattedArrivalTime)
                        .font(DesignSystem.Typography.monoLarge)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fontWeight(.bold)
                }
            }
            
            // Bottom section with leave by time and action
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LEAVE BY")
                        .font(DesignSystem.Typography.captionMono)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    Text(calculateLeaveByTime())
                        .font(DesignSystem.Typography.monoMedium)
                        .foregroundColor(DesignSystem.Colors.warning)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Calendar button
                Button(action: addToCalendar) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Add")
                            .font(DesignSystem.Typography.bodySmall)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                            .fill(DesignSystem.Colors.surfaceElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                    )
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(DesignSystem.Animation.quick, value: isPressed)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .fill(DesignSystem.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                        .stroke(
                            isNextTrain ? DesignSystem.Colors.accent : DesignSystem.Colors.border,
                            lineWidth: isNextTrain ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isNextTrain ? DesignSystem.Colors.accent.opacity(0.1) : DesignSystem.Shadow.small,
            radius: isNextTrain ? 8 : 4,
            x: 0,
            y: isNextTrain ? 4 : 2
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(DesignSystem.Animation.bounce, value: isPressed)
        .onTapGesture {
            withAnimation(DesignSystem.Animation.quick) {
                isPressed.toggle()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.Animation.quick) {
                    isPressed.toggle()
                }
            }
        }
        .onAppear {
            if isNextTrain {
                isPressed = true
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func calculateLeaveByTime() -> String {
        guard let departureDate = train.departureDateTime(on: Date()) else {
            return "N/A"
        }
        let leaveByDate = departureDate.addingTimeInterval(-Double(averageTimeToStation * 60))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: leaveByDate)
    }
    
    private func addToCalendar() {
        Task {
            do {
                let success = try await CalendarService.shared.addTrainEvent(
                    train: train,
                    departureStation: departureStation,
                    arrivalStation: arrivalStation,
                    leaveByTime: calculateLeaveByTime()
                )
                await MainActor.run {
                    alertTitle = success ? "Success" : "Error"
                    alertMessage = success ? "Train journey added to your calendar" : "Failed to add to calendar"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
} 