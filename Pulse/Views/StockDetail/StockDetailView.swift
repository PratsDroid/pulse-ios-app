import SwiftUI

struct StockDetailView: View {
    @StateObject private var viewModel: StockDetailViewModel
    
    init(stock: Stock) {
        _viewModel = StateObject(wrappedValue: StockDetailViewModel(stock: stock))
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingView(message: "Loading stock data...")
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header with price info
                        StockHeaderView(stock: viewModel.stock)
                        
                        // Robinhood-style interactive chart
                        if !viewModel.priceHistory.isEmpty {
                            RobinhoodChartView(
                                data: viewModel.priceHistory,
                                isPositive: viewModel.stock.isPositive
                            ) { period in
                                // When user changes time period, fetch new data
                                Task {
                                    await viewModel.loadDataForPeriod(period)
                                }
                            }
                        } else if viewModel.error != nil {
                            // Error state - show message
                            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                .fill(Color.cardBackground)
                                .frame(height: 400)
                                .overlay {
                                    VStack(spacing: 12) {
                                        Image(systemName: "chart.line.uptrend.xyaxis.circle")
                                            .font(.system(size: 48))
                                            .foregroundColor(.secondary)
                                        
                                        Text("Unable to load chart data")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("Check your API configuration")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Button("Retry") {
                                            Task {
                                                await viewModel.loadPriceHistory()
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .padding(.top, 8)
                                    }
                                }
                        } else {
                            // Loading state
                            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                                .fill(Color.cardBackground)
                                .frame(height: 400)
                                .overlay {
                                    ProgressView("Loading chart...")
                                }
                        }
                        
                        // Key Statistics
                        KeyStatisticsView(stock: viewModel.stock)
                        
                        // AI Analysis Buttons
                        VStack(spacing: 12) {
                            AIAnalysisButton(
                                title: "General AI Analysis",
                                icon: "brain.head.profile",
                                type: .general
                            ) {
                                viewModel.selectedAnalysisType = .general
                            }
                            
                            AIAnalysisButton(
                                title: "1-Month Technical Forecast",
                                icon: "calendar",
                                type: .monthForecast
                            ) {
                                viewModel.selectedAnalysisType = .monthForecast
                            }
                            
                            AIAnalysisButton(
                                title: "1-Week Technical Forecast",
                                icon: "calendar.badge.clock",
                                type: .weekForecast
                            ) {
                                viewModel.selectedAnalysisType = .weekForecast
                            }
                        }
                        
                        placeholderSection(title: "Company News", icon: "newspaper")
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .sheet(item: $viewModel.selectedAnalysisType) { type in
                    NavigationStack {
                        AIAnalysisView(
                            stock: viewModel.stock,
                            priceHistory: viewModel.fullPriceHistory.isEmpty ? viewModel.priceHistory : viewModel.fullPriceHistory,
                            analysisType: type
                        )
                    }
                }
            }
        }
        .navigationTitle(viewModel.stock.ticker)
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.toggleWatchlist()
                } label: {
                    Image(systemName: viewModel.isInWatchlist ? "star.fill" : "star")
                        .foregroundColor(viewModel.isInWatchlist ? .yellow : .primary)
                }
            }
        }
        .task {
            // Load initial data
            viewModel.checkWatchlistStatus()
            await viewModel.loadData()
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.error) { error in
            Button("OK", role: .cancel) {}
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private var aiAnalysisButton: some View {
        VStack(spacing: 12) {
            HStack {
                Label("AI Analysis", systemImage: "brain.head.profile")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(Constants.UI.cornerRadius)
        }
    }
    
    private func placeholderSection(title: String, icon: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Coming soon in Phase 3")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

#Preview {
    StockDetailView(stock: Stock.sample)
        .preferredColorScheme(.dark)
}
