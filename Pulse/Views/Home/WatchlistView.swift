import SwiftUI

struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var showingSearch = false
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView(message: "Loading watchlist...")
                } else {
                    VStack(spacing: 0) {
                        // Search Bar
                        searchBar
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                // Market Overview
                                if !viewModel.marketIndices.isEmpty {
                                    marketOverviewSection
                                }
                                
                                // Header
                                headerView
                                
                                // Stock List
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.watchlist.stocks) { stock in
                                        NavigationLink(value: stock) {
                                            StockRowView(stock: stock)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .onDelete(perform: viewModel.removeStock)
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, 12)
                        }
                        .refreshable {
                            await viewModel.refreshStocks()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Stock.self) { stock in
                StockDetailView(stock: stock)
            }
            .sheet(isPresented: $showingSearch) {
                StockSearchView { stock in
                    showingSearch = false
                    // Small delay to ensure sheet dismisses before pushing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        path.append(stock)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.error) { error in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
            .task {
                await viewModel.loadWatchlist()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Last updated: \(viewModel.watchlist.lastUpdated.asRelativeTime)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if viewModel.isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
    
    private var marketOverviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Market Overview")
                .font(.title2.bold())
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.marketIndices) { idx in
                        NavigationLink(value: idx) {
                            MarketIndexCard(stock: idx)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var searchBar: some View {
        Button {
            showingSearch = true
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                Text("Search stocks...")
                    .foregroundColor(.secondary)
                    .font(.body)
                
                Spacer()
            }
            .padding(12)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WatchlistView()
        .preferredColorScheme(.dark)
}
