import SwiftUI

// Assuming Train model is accessible here. 
// It would typically be imported from your Models directory.

struct TrainCard: View {
    let train: Train
    let departureStation: String
    let arrivalStation: String
    @AppStorage("averageTimeToStation") var averageTimeToStation: Int = 15 // Default to 15 minutes
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 15) { // Reduced spacing
            // Route badge and Duration
            HStack {
                Text(train.routeShortName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text("\(train.durationInMinutes) min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Horizontal Train line graphic
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(height: 2)
                Image(systemName: "train.side.front.car")
                    .foregroundColor(.blue)
                    .font(.title2) // Adjusted icon size
                Rectangle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(height: 2)
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
            .padding(.horizontal, 50) // Add some padding to align with station text below

            // Stations
            HStack(alignment: .top) { // Align to top for better visual consistency
                VStack(alignment: .leading) {
                    Text(departureStation)
                        .font(.headline)
                    Text(train.formattedDepartureTime)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(arrivalStation)
                        .font(.headline)
                    Text(train.formattedArrivalTime)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            // Leave by time and Calendar button
            HStack {
                VStack(alignment: .leading) {
                    Text("Leave by: \(calculateLeaveByTime())")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                Spacer()
                Button(action: {
                    // Add to calendar
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
                }) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 5)
        }
        .padding(15) // Adjusted padding
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8) // Adjusted shadow
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
            // Return a default/error string or handle appropriately
            return "N/A"
        }
        let leaveByDate = departureDate.addingTimeInterval(-Double(averageTimeToStation * 60))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: leaveByDate)
    }
}