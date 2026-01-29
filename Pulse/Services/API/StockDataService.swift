import Foundation

/// Protocol defining the interface for stock data services
/// This allows easy swapping between different API providers (Polygon, Yahoo Finance, Alpha Vantage, etc.)
protocol StockDataService: Actor {
    /// Get current stock quote with daily data
    func getStockQuote(ticker: String) async throws -> Stock
    
    /// Get historical price data for charts
    func getHistoricalData(ticker: String, from: Date, to: Date) async throws -> [PricePoint]
    
    /// Search for stocks by ticker or company name
    func searchStocks(query: String) async throws -> [StockSearchResult]
    
    /// Get detailed stock information
    func getStockDetails(ticker: String) async throws -> Stock
    
    /// Clear cache
    func clearCache()
}
