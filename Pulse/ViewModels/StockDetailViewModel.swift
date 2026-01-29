import Foundation
import Combine

@MainActor
class StockDetailViewModel: ObservableObject {
    @Published var stock: Stock
    @Published var priceHistory: [PricePoint] = []
    @Published var selectedTimeframe: Constants.ChartTimeframe = .oneDay
    @Published var selectedAnalysisType: AIAnalysisType?
    @Published var isLoading = false
    @Published var error: APIError?
    @Published var showError = false
    @Published var isInWatchlist = false
    
    private let apiService = StockDataServiceManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Cache full year of data to avoid multiple API calls
    private var _fullPriceHistory: [PricePoint] = []
    
    var fullPriceHistory: [PricePoint] { _fullPriceHistory }
    
    init(stock: Stock) {
        self.stock = stock
        self.checkWatchlistStatus()
    }
    
    // MARK: - Public Methods
    
    func checkWatchlistStatus() {
        let tickers = DataManager.shared.loadWatchlistTickers()
        isInWatchlist = tickers.contains(stock.ticker)
    }
    
    func toggleWatchlist() {
        do {
            if isInWatchlist {
                try DataManager.shared.removeFromWatchlist(ticker: stock.ticker)
            } else {
                try DataManager.shared.addToWatchlist(ticker: stock.ticker, companyName: stock.companyName)
            }
            // Update local state immediately
            isInWatchlist.toggle()
        } catch {
            print("❌ Error toggling watchlist: \(error)")
        }
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Just load price history - we already have stock data from watchlist
            await loadPriceHistory()
            
        } catch let apiError as APIError {
            error = apiError
            showError = true
        } catch {
            self.error = .networkError(error)
            showError = true
        }
    }
    
    func loadPriceHistory() async {
        // If in mock mode, use sample data
        if Constants.API.useMockData {
            let sampleData = PricePoint.generateSampleData(
                days: selectedTimeframe.days,
                basePrice: stock.currentPrice
            )
            print("🎭 MOCK MODE: Using \(sampleData.count) sample data points")
            priceHistory = sampleData
            return
        }
        
        // Load full year of data once
        await loadFullPriceHistory()
        
        // Filter to selected timeframe
        filterPriceHistory(days: selectedTimeframe.days)
    }
    
    /// Load full year of price data (called once, cached in memory)
    private func loadFullPriceHistory() async {
        // If we already have full data, skip
        if !_fullPriceHistory.isEmpty {
            print("📦 Using cached full price history (\(_fullPriceHistory.count) points)")
            return
        }
        
        let calendar = Calendar.current
        let to = Date()
        // Fetch 1 year of data (covers all time periods: 1D, 5D, 1M, 3M, 6M, YTD)
        guard let from = calendar.date(byAdding: .day, value: -370, to: to) else {
            return
        }
        
        print("📊 Loading full price history for \(stock.ticker) (370 days)")
        
        // Check database cache first
        if let cached = await DataManager.shared.getCachedPriceHistory(ticker: stock.ticker, from: from, to: to, maxAge: 300) {
            _fullPriceHistory = cached
            print("✅ Loaded \(cached.count) points from database cache")
            return
        }
        
        do {
            let history = try await apiService.getHistoricalData(
                ticker: stock.ticker,
                from: from,
                to: to
            )
            print("✅ Loaded \(history.count) price points from API")
            _fullPriceHistory = history
            
            // Cache the result in database
            await DataManager.shared.cachePriceHistory(ticker: stock.ticker, from: from, to: to, pricePoints: history)
            
        } catch let apiError as APIError {
            print("⚠️ API Error loading history: \(apiError)")
            error = apiError
            showError = true
            _fullPriceHistory = []
        } catch {
            print("⚠️ Error loading history: \(error)")
            self.error = .networkError(error)
            showError = true
            _fullPriceHistory = []
        }
    }
    
    /// Filter full price history to specific number of days (instant, client-side)
    private func filterPriceHistory(days: Int) {
        guard !_fullPriceHistory.isEmpty else {
            priceHistory = []
            return
        }
        
        let calendar = Calendar.current
        let to = Date()
        guard let from = calendar.date(byAdding: .day, value: -days, to: to) else {
            priceHistory = _fullPriceHistory
            return
        }
        
        let filtered = _fullPriceHistory.filter { $0.date >= from }
        priceHistory = filtered
        print("📊 Filtered to \(filtered.count) points for last \(days) days")
    }
    
    func changeTimeframe(_ timeframe: Constants.ChartTimeframe) async {
        selectedTimeframe = timeframe
        await loadPriceHistory()
    }
    
    /// Load data for a specific chart period (called from RobinhoodChartView)
    func loadDataForPeriod(_ period: RobinhoodChartView.TimePeriod) async {
        print("📊 User selected period: \(period.rawValue) (\(period.days) days)")
        
        // If in mock mode, use sample data
        if Constants.API.useMockData {
            let sampleData = PricePoint.generateSampleData(
                days: period.days,
                basePrice: stock.currentPrice
            )
            print("🎭 MOCK MODE: Using \(sampleData.count) sample data points")
            priceHistory = sampleData
            return
        }
        
        // Load full year of data if not already loaded (one API call)
        await loadFullPriceHistory()
        
        // Filter to requested period (instant, client-side)
        filterPriceHistory(days: period.days)
    }
    
    /// Refresh data (clears cache and reloads)
    func refresh() async {
        _fullPriceHistory = []  // Clear cache
        await loadData()
    }
}
