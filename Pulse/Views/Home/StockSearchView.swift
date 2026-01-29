import SwiftUI

struct StockSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recentSearchManager = RecentSearchManager()
    @State private var searchText = ""
    @State private var searchResults: [StockSearchResult] = []
    @State private var isSearching = false
    @State private var error: APIError?
    @State private var showError = false
    @FocusState private var isSearchFocused: Bool
    
    let onSelectStock: (Stock) -> Void
    
    private let apiService = StockDataServiceManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Recent Section
                            if searchText.isEmpty && !recentSearchManager.recentSearches.isEmpty {
                                recentSection
                            }
                            
                            // Search Results
                            if !searchText.isEmpty {
                                if isSearching {
                                    LoadingView(message: "Searching...")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .padding(.top, 100)
                                } else if searchResults.isEmpty {
                                    emptyStateView
                                        .padding(.top, 100)
                                } else {
                                    searchResultsList
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isSearchFocused = true
            }
            .alert("Error", isPresented: $showError, presenting: error) { error in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.body)
                
                TextField("Search", text: $searchText)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .foregroundColor(.primary)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(10)
        }
        .padding()
        .onChange(of: searchText) { _, newValue in
            Task {
                await performSearch(query: newValue)
            }
        }
    }
    
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Clear") {
                    recentSearchManager.clearRecentSearches()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(recentSearchManager.recentSearches) { result in
                    Button {
                        selectStock(result)
                    } label: {
                        recentSearchRow(result)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func recentSearchRow(_ result: StockSearchResult) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.ticker)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(result.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var searchResultsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(searchResults) { result in
                Button {
                    selectStock(result)
                } label: {
                    searchResultRow(result)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func searchResultRow(_ result: StockSearchResult) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.ticker)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(result.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No results found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try searching for a different ticker or company name")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // Debounce search
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        guard query == searchText else { return }
        
        isSearching = true
        defer { isSearching = false }
        
        do {
            let results = try await apiService.searchStocks(query: query)
            searchResults = results
        } catch let apiError as APIError {
            error = apiError
            showError = true
            searchResults = []
        } catch {
            self.error = .networkError(error)
            showError = true
            searchResults = []
        }
    }
    
    private func selectStock(_ result: StockSearchResult) {
        // Add to recent searches
        recentSearchManager.addSearch(result)
        
        Task {
            do {
                let stock = try await apiService.getStockDetails(ticker: result.ticker)
                onSelectStock(stock)
                dismiss()
            } catch let apiError as APIError {
                error = apiError
                showError = true
            } catch {
                self.error = .networkError(error)
                showError = true
            }
        }
    }
}

#Preview {
    StockSearchView { stock in
        print("Selected: \(stock.ticker)")
    }
    .preferredColorScheme(.dark)
}
