import Foundation

/// Manages stock data services with intelligent provider selection
/// Uses Finnhub for quotes, Twelve Data for historical data and indicators
actor StockDataServiceManager {
    static let shared = StockDataServiceManager()
    
    private(set) var currentService: any StockDataService
    private let finnhubService = FinnhubAPIService.shared
    private let twelveDataService = TwelveDataAPIService.shared
    private let polygonService = PolygonAPIService.shared
    
    private init() {
        // Default to Twelve Data
        currentService = twelveDataService
    }
    
    /// Switch to a different stock data service
    func switchService(to service: any StockDataService) {
        currentService = service
    }
    
    // MARK: - Smart Provider Selection
    
    /// Get stock quote - uses Finnhub (60/min) with Twelve Data fallback
    func getStockQuote(ticker: String) async throws -> Stock {
        // Try Finnhub first for real-time quotes (generous 60/min rate limit)
        do {
            return try await finnhubService.getStockQuote(ticker: ticker)
        } catch {
            print("⚠️ Finnhub quote failed, trying Twelve Data: \(error)")
            
            // Fallback to Twelve Data
            do {
                return try await twelveDataService.getStockQuote(ticker: ticker)
            } catch {
                print("⚠️ Twelve Data quote failed, falling back to Polygon: \(error)")
                return try await polygonService.getStockQuote(ticker: ticker)
            }
        }
    }
    
    /// Get historical data - uses Twelve Data (only free provider with historical candles)
    func getHistoricalData(ticker: String, from: Date, to: Date) async throws -> [PricePoint] {
        // Twelve Data is the only free provider with historical candles
        do {
            return try await twelveDataService.getHistoricalData(ticker: ticker, from: from, to: to)
        } catch {
            print("⚠️ Twelve Data historical failed, falling back to Polygon: \(error)")
            return try await polygonService.getHistoricalData(ticker: ticker, from: from, to: to)
        }
    }
    
    /// Search stocks - uses Finnhub (better search) with Twelve Data fallback
    func searchStocks(query: String) async throws -> [StockSearchResult] {
        // Try Finnhub first for better search results
        do {
            return try await finnhubService.searchStocks(query: query)
        } catch {
            print("⚠️ Finnhub search failed, trying Twelve Data: \(error)")
            
            // Fallback to Twelve Data
            do {
                return try await twelveDataService.searchStocks(query: query)
            } catch {
                print("⚠️ Twelve Data search failed, falling back to Polygon: \(error)")
                return try await polygonService.searchStocks(query: query)
            }
        }
    }
    
    /// Get stock details - uses Finnhub (richer data) with Twelve Data fallback
    func getStockDetails(ticker: String) async throws -> Stock {
        // Try Finnhub first for richer company data
        do {
            return try await finnhubService.getStockDetails(ticker: ticker)
        } catch {
            print("⚠️ Finnhub details failed, trying Twelve Data: \(error)")
            
            // Fallback to Twelve Data
            do {
                return try await twelveDataService.getStockDetails(ticker: ticker)
            } catch {
                print("⚠️ Twelve Data details failed, falling back to Polygon: \(error)")
                return try await polygonService.getStockDetails(ticker: ticker)
            }
        }
    }
    
    // MARK: - Twelve Data Exclusive Features
    
    /// Get RSI (Relative Strength Index) - Twelve Data exclusive
    func getRSI(ticker: String, period: Int = 14) async throws -> [Double] {
        try await twelveDataService.getRSI(ticker: ticker, period: period)
    }
    
    /// Get MACD - Twelve Data exclusive
    func getMACD(ticker: String) async throws -> [(macd: Double, signal: Double, histogram: Double)] {
        try await twelveDataService.getMACD(ticker: ticker)
    }
    
    /// Clear cache on all providers
    func clearCache() async {
        await finnhubService.clearCache()
        await twelveDataService.clearCache()
        await polygonService.clearCache()
    }
}
