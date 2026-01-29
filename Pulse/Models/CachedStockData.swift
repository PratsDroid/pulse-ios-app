import Foundation
import SwiftData

/// Cached stock quote data
@Model
final class CachedStockQuote {
    @Attribute(.unique) var ticker: String
    var companyName: String
    var currentPrice: Double
    var dailyChange: Double
    var dailyChangePercent: Double
    var volume: Int
    var previousClose: Double
    var openPrice: Double
    var timestamp: Date
    
    init(
        ticker: String,
        companyName: String,
        currentPrice: Double,
        dailyChange: Double,
        dailyChangePercent: Double,
        volume: Int,
        previousClose: Double,
        openPrice: Double,
        timestamp: Date = Date()
    ) {
        self.ticker = ticker
        self.companyName = companyName
        self.currentPrice = currentPrice
        self.dailyChange = dailyChange
        self.dailyChangePercent = dailyChangePercent
        self.volume = volume
        self.previousClose = previousClose
        self.openPrice = openPrice
        self.timestamp = timestamp
    }
    
    /// Convert to Stock model
    func toStock() -> Stock {
        Stock(
            ticker: ticker,
            companyName: companyName,
            currentPrice: currentPrice,
            dailyChange: dailyChange,
            dailyChangePercent: dailyChangePercent,
            volume: volume,
            previousClose: previousClose,
            openPrice: openPrice,
            lastUpdated: timestamp
        )
    }
    
    /// Create from Stock model
    static func from(_ stock: Stock) -> CachedStockQuote {
        CachedStockQuote(
            ticker: stock.ticker,
            companyName: stock.companyName,
            currentPrice: stock.currentPrice,
            dailyChange: stock.dailyChange,
            dailyChangePercent: stock.dailyChangePercent,
            volume: stock.volume,
            previousClose: stock.previousClose ?? stock.currentPrice,
            openPrice: stock.openPrice ?? stock.currentPrice,
            timestamp: stock.lastUpdated
        )
    }
}

/// Cached historical price data
@Model
final class CachedPriceHistory {
    @Attribute(.unique) var id: String  // ticker-fromDate-toDate
    var ticker: String
    var fromDate: Date
    var toDate: Date
    var pricePointsData: Data  // JSON encoded [PricePoint]
    var timestamp: Date
    
    init(
        ticker: String,
        fromDate: Date,
        toDate: Date,
        pricePoints: [PricePoint],
        timestamp: Date = Date()
    ) {
        self.ticker = ticker
        self.fromDate = fromDate
        self.toDate = toDate
        self.timestamp = timestamp
        
        // Create unique ID
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.id = "\(ticker)-\(formatter.string(from: fromDate))-\(formatter.string(from: toDate))"
        
        // Encode price points
        self.pricePointsData = (try? JSONEncoder().encode(pricePoints)) ?? Data()
    }
    
    /// Get decoded price points
    var pricePoints: [PricePoint] {
        (try? JSONDecoder().decode([PricePoint].self, from: pricePointsData)) ?? []
    }
}
