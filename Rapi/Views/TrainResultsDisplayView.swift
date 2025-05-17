import SwiftUI

// Assuming Train model is accessible here, or we might need to pass more specific data.
// If Train is not in scope, this will need adjustment.
// We also need access to TrainCard, or it should be passed in or made more generic.

struct TrainResultsDisplayView: View {
    let isLoading: Bool
    let errorMessage: String?
    let train: Train? // Assuming Train is a defined type
    let departureStationName: String
    let arrivalStationName: String
    let departureStationId: String
    let arrivalStationId: String

    var body: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(1.5)
                .padding(.top, 40)
                .frame(maxWidth: .infinity)
        } else if let errorMessage = errorMessage {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .padding(.bottom, 8)
                Text(errorMessage)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10)
            .padding()
            .padding(.top, 20)
        } else if let train = train {
            // Assuming TrainCard is accessible here
            TrainCard(train: train, departureStation: departureStationName, arrivalStation: arrivalStationName)
                .padding()
                .padding(.top, 20)
                .padding(.bottom, 90) // Add extra padding at bottom to avoid tab bar overlap
        } else if !departureStationId.isEmpty && !arrivalStationId.isEmpty {
            VStack {
                Image(systemName: "arrow.down.circle")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .padding(.bottom, 8)
                Text("Tap 'Find Next Train' to see the next available train")
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10)
            .padding()
            .padding(.top, 20)
        } else {
            // Empty state
            VStack(spacing: 16) {
                Image(systemName: "train.side.front.car")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                    .padding(.top, 40)
                
                Text("Select departure and arrival stations to find the next train")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
        }
    }
}

// It's good practice to include previews for components if they can be displayed meaningfully.
// However, TrainResultsDisplayView depends on 'Train' and 'TrainCard' which might not be defined
// in this isolated context without further information or moving them.
// For now, I'll omit the preview for this new component.
// If 'Train' and 'TrainCard' are in separate files, they need to be imported or made accessible.

// Placeholder for Train and TrainCard if they are not globally available
// This is just for the sake of making the file compilable in isolation for now.
// In a real project, Train would be defined in Models/ and TrainCard might be in Components/ or Views/.
/*
 struct Train: Identifiable {
 let id = UUID()
 let routeShortName: String
 let durationInMinutes: Int
 let formattedDepartureTime: String
 let formattedArrivalTime: String
 let routeLongName: String
 }
 
 struct TrainCard: View {
 let train: Train
 let departureStation: String
 let arrivalStation: String
 var body: some View { Text("Train Card Placeholder") }
 }
 */ 