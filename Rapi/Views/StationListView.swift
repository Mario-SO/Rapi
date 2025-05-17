import SwiftUI
import Combine

struct StationListView: View {
    @StateObject private var viewModel = StationListViewModel()
    @State private var searchText = ""
    
    // For search debouncing
    @State private var searchSubject = PassthroughSubject<String, Never>()
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            // Search bar
            TextField("Search Stations", text: $searchText)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .onChange(of: searchText) { oldValue, newValue in
                    searchSubject.send(newValue)
                }
            
            // Station list
            if viewModel.isLoading {
                ProgressView("Loading stations...")
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage, retryAction: {
                    viewModel.fetchStations()
                })
            } else {
                List {
                    ForEach(viewModel.stations) { station in
                        NavigationLink(destination: StationDetailView(station: station)) {
                            StationRow(station: station)
                        }
                    }
                    // Add a clear spacer at the bottom
                    Color.clear
                        .frame(height: 90) // Adjust height as needed for your tab bar
                        .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.fetchStationsAsync()
                }
            }
        }
        .navigationTitle("Stations")
        .onAppear {
            setupSearchDebounce()
            viewModel.fetchStations()
        }
    }
    
    // Setup search debouncing to prevent UI flickering
    private func setupSearchDebounce() {
        searchSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // 300ms debounce
            .sink { [weak viewModel] searchTerm in
                viewModel?.searchQuery = searchTerm
                viewModel?.fetchStations()
            }
            .store(in: &cancellables)
    }
}

struct StationRow: View {
    let station: StationApiModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(station.stopName)
                .font(.headline)
            
            Text("ID: \(station.stopId)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Error")
                .font(.title)
                .foregroundColor(.red)
            
            Text(message)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                retryAction()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

struct StationListView_Previews: PreviewProvider {
    static var previews: some View {
        StationListView()
    }
} 
