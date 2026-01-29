import Foundation
import Combine

@MainActor
class WatchlistViewModel: ObservableObject {
    @Published var watchlist: Watchlist = Watchlist()
    @Published var marketIndices: [Stock] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: APIError?
    @Published var showError = false
    
    private let apiService = StockDataServiceManager.shared
    private let dataManager = DataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    // MARK: - Public Methods
    
    func loadWatchlist() async {
        if watchlist.stocks.isEmpty {
            isLoading = true
        }
        defer { isLoading = false }
        
        // Load saved tickers from SwiftData
        let savedTickers = dataManager.loadWatchlistTickers()
        
        // If no saved tickers, use defaults
        let tickers = savedTickers.isEmpty ? ["AAPL"] : savedTickers
        
        do {
            // Fetch all stocks concurrently (using quotes, not full details)
            async let indices = fetchMarketIndices()
            async let stocks = fetchWatchlistStocks(tickers: tickers)
            
            marketIndices = try await indices
            watchlist = Watchlist(stocks: try await stocks)
            
            print("debug: Market indices loaded: \(marketIndices.count) -> \(marketIndices.map { $0.ticker })")
            
            // Save tickers to SwiftData if we used defaults
            if savedTickers.isEmpty {
                try? dataManager.saveWatchlistTickers(tickers)
            }
            
        } catch let apiError as APIError {
            error = apiError
            showError = true
            // Fallback to sample data on error
            watchlist = Watchlist(stocks: Stock.samples)
        } catch {
            self.error = .networkError(error)
            showError = true
            // Fallback to sample data on error
            watchlist = Watchlist(stocks: Stock.samples)
        }
    }
    
    private func fetchMarketIndices() async throws -> [Stock] {
        let tickers = ["SPY", "QQQ", "DIA"]
        return try await fetchStocks(tickers: tickers)
    }
    
    private func fetchWatchlistStocks(tickers: [String]) async throws -> [Stock] {
        let stocks = try await fetchStocks(tickers: tickers)
        return stocks.sorted { $0.ticker < $1.ticker }
    }
    
    private func fetchStocks(tickers: [String]) async throws -> [Stock] {
        try await withThrowingTaskGroup(of: Stock?.self) { group in
            for ticker in tickers {
                group.addTask {
                    // Check cache first
                    if let cached = await DataManager.shared.getCachedQuote(ticker: ticker, maxAge: 60) {
                        return cached
                    }
                    // Fetch from API
                    do {
                        let stock = try await self.apiService.getStockQuote(ticker: ticker)
                        await DataManager.shared.cacheQuote(stock)
                        return stock
                    } catch {
                        print("⚠️ Failed to fetch \(ticker): \(error)")
                        return nil
                    }
                }
            }
            
            var results: [Stock] = []
            for try await stock in group {
                if let stock = stock {
                    results.append(stock)
                }
            }
            return results
        }
    }
    
    func refreshStocks() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            async let indices = fetchMarketIndices()
            async let stocks = fetchWatchlistStocks(tickers: watchlist.stocks.map { $0.ticker })
            
            marketIndices = try await indices
            watchlist.stocks = try await stocks
            watchlist.lastUpdated = Date()
            
        } catch let apiError as APIError {
            error = apiError
            showError = true
        } catch {
            self.error = .networkError(error)
            showError = true
        }
    }
    
    func addStock(_ stock: Stock) {
        watchlist.addStock(stock)
        saveWatchlist()
    }
    
    func removeStock(ticker: String) {
        watchlist.removeStock(ticker: ticker)
        saveWatchlist()
    }
    
    func removeStock(at offsets: IndexSet) {
        let tickersToRemove = offsets.map { watchlist.stocks[$0].ticker }
        tickersToRemove.forEach { removeStock(ticker: $0) }
    }
    
    // MARK: - Private Methods
    
    private func saveWatchlist() {
        let tickers = watchlist.stocks.map { $0.ticker }
        try? dataManager.saveWatchlistTickers(tickers)
    }
}
