import SwiftUI
import Combine

struct RouteListView: View {
    @StateObject private var viewModel = RouteListViewModel()
    
    var body: some View {
        VStack {
            // Route list
            if viewModel.isLoading {
                ProgressView("Loading routes...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage, retryAction: {
                    viewModel.fetchRoutes()
                })
            } else {
                List {
                    ForEach(viewModel.routes) { route in
                        NavigationLink(destination: RouteDetailView(routeId: route.routeId, routeName: route.routeLongName)) {
                            RouteRow(route: route)
                        }
                    }
                    // Add a clear spacer at the bottom
                    Color.clear
                        .frame(height: 90) // Adjust height as needed for your tab bar
                        .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.fetchRoutesAsync()
                }
            }
        }
        .navigationTitle("Routes")
        .onAppear {
            viewModel.fetchRoutes()
        }
    }
}

struct RouteRow: View {
    let route: RouteModel
    
    // Format route name to properly space hyphens with more aggressive cleaning
    private var formattedRouteName: String {
        // First remove all excess whitespace, then format properly
        let trimmed = route.routeLongName.trimmingCharacters(in: .whitespaces)
        
        // Step 1: Collapse all whitespace to single spaces
        let noExtraSpaces = trimmed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Step 2: Replace hyphens with properly spaced hyphens
        let properlySpacedHyphens = noExtraSpaces
            .replacingOccurrences(of: "\\s*-\\s*", with: " - ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        return properlySpacedHyphens
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(route.routeShortName)
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                Text(formattedRouteName)
                    .font(.headline)
            }
            
            Text("ID: \(route.routeId)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct RouteListView_Previews: PreviewProvider {
    static var previews: some View {
        RouteListView()
    }
} 