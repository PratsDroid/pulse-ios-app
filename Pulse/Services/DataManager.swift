import Foundation
import SwiftData

@MainActor
class DataManager {
    static let shared = DataManager()
    
    let modelContainer: ModelContainer
    
    private init() {
        do {
            let schema = Schema([
                WatchlistStock.self,
                CachedStockQuote.self,
                CachedPriceHistory.self,
                CachedAIAnalysis.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ SwiftData initialized successfully")
            print("📁 Store URL: \(modelContainer.configurations.first?.url.path ?? "unknown")")
        } catch {
            print("❌ Failed to initialize SwiftData: \(error)")
            fatalError("Could not initialize SwiftData: \(error)")
        }
    }
    
    // MARK: - Watchlist Operations
    
    func saveWatchlistTickers(_ tickers: [String]) throws {
        let context = ModelContext(modelContainer)
        
        print("💾 Saving tickers to SwiftData: \(tickers)")
        
        // Delete all existing
        try context.delete(model: WatchlistStock.self)
        
        // Add new tickers
        for (index, ticker) in tickers.enumerated() {
            let stock = WatchlistStock(ticker: ticker, sortOrder: index)
            context.insert(stock)
        }
        
        try context.save()
        print("✅ Successfully saved \(tickers.count) tickers")
    }
    
    func loadWatchlistTickers() -> [String] {
        let context = ModelContext(modelContainer)
        
        let descriptor = FetchDescriptor<WatchlistStock>(sortBy: [SortDescriptor(\.sortOrder)])
        
        do {
            let stocks = try context.fetch(descriptor)
            let tickers = stocks.map { $0.ticker }
            print("📖 Loaded \(tickers.count) tickers from SwiftData: \(tickers)")
            return tickers
        } catch {
            print("❌ Failed to fetch watchlist: \(error)")
            return []
        }
    }
    
    func addToWatchlist(ticker: String, companyName: String? = nil) throws {
        let context = ModelContext(modelContainer)
        
        // Check if already exists
        let predicate = #Predicate<WatchlistStock> { $0.ticker == ticker }
        let descriptor = FetchDescriptor<WatchlistStock>(predicate: predicate)
        
        if let existing = try context.fetch(descriptor).first {
            // Update company name if provided
            if let name = companyName {
                existing.companyName = name
            }
        } else {
            // Get next sort order
            let allDescriptor = FetchDescriptor<WatchlistStock>()
            let count = try context.fetchCount(allDescriptor)
            
            let stock = WatchlistStock(ticker: ticker, companyName: companyName, sortOrder: count)
            context.insert(stock)
        }
        
        try context.save()
    }
    
    func removeFromWatchlist(ticker: String) throws {
        let context = ModelContext(modelContainer)
        
        let predicate = #Predicate<WatchlistStock> { $0.ticker == ticker }
        let descriptor = FetchDescriptor<WatchlistStock>(predicate: predicate)
        
        if let stock = try context.fetch(descriptor).first {
            context.delete(stock)
            try context.save()
        }
    }
    
    // MARK: - Stock Quote Cache
    
    func getCachedQuote(ticker: String, maxAge: TimeInterval = 60) -> Stock? {
        let context = ModelContext(modelContainer)
        
        let predicate = #Predicate<CachedStockQuote> { $0.ticker == ticker }
        let descriptor = FetchDescriptor<CachedStockQuote>(predicate: predicate)
        
        guard let cached = try? context.fetch(descriptor).first else {
            return nil
        }
        
        // Check if cache is still valid
        let age = Date().timeIntervalSince(cached.timestamp)
        if age > maxAge {
            print("⏰ Cache expired for \(ticker) (age: \(Int(age))s)")
            return nil
        }
        
        print("✅ Using cached quote for \(ticker) (age: \(Int(age))s)")
        return cached.toStock()
    }
    
    func cacheQuote(_ stock: Stock) {
        let context = ModelContext(modelContainer)
        
        let predicate = #Predicate<CachedStockQuote> { $0.ticker == stock.ticker }
        let descriptor = FetchDescriptor<CachedStockQuote>(predicate: predicate)
        
        // Delete existing cache
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
        
        // Insert new cache
        let cached = CachedStockQuote.from(stock)
        context.insert(cached)
        
        try? context.save()
        print("💾 Cached quote for \(stock.ticker)")
    }
    
    // MARK: - Price History Cache
    
    func getCachedPriceHistory(ticker: String, from: Date, to: Date, maxAge: TimeInterval = 300) -> [PricePoint]? {
        let context = ModelContext(modelContainer)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let id = "\(ticker)-\(formatter.string(from: from))-\(formatter.string(from: to))"
        
        let predicate = #Predicate<CachedPriceHistory> { $0.id == id }
        let descriptor = FetchDescriptor<CachedPriceHistory>(predicate: predicate)
        
        guard let cached = try? context.fetch(descriptor).first else {
            return nil
        }
        
        // Check if cache is still valid
        let age = Date().timeIntervalSince(cached.timestamp)
        if age > maxAge {
            print("⏰ Price history cache expired for \(ticker) (age: \(Int(age))s)")
            return nil
        }
        
        print("✅ Using cached price history for \(ticker) (age: \(Int(age))s, \(cached.pricePoints.count) points)")
        return cached.pricePoints
    }
    
    func cachePriceHistory(ticker: String, from: Date, to: Date, pricePoints: [PricePoint]) {
        let context = ModelContext(modelContainer)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let id = "\(ticker)-\(formatter.string(from: from))-\(formatter.string(from: to))"
        
        let predicate = #Predicate<CachedPriceHistory> { $0.id == id }
        let descriptor = FetchDescriptor<CachedPriceHistory>(predicate: predicate)
        
        // Delete existing cache
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
        
        // Insert new cache
        let cached = CachedPriceHistory(ticker: ticker, fromDate: from, toDate: to, pricePoints: pricePoints)
        context.insert(cached)
        
        try? context.save()
        print("💾 Cached price history for \(ticker) (\(pricePoints.count) points)")
    }
    
    // MARK: - Cache Management
    
    func clearExpiredCaches() {
        let context = ModelContext(modelContainer)
        
        // Clear quotes older than 5 minutes
        let quoteDescriptor = FetchDescriptor<CachedStockQuote>()
        if let quotes = try? context.fetch(quoteDescriptor) {
            let expiredQuotes = quotes.filter { Date().timeIntervalSince($0.timestamp) > 300 }
            expiredQuotes.forEach { context.delete($0) }
            if !expiredQuotes.isEmpty {
                print("🗑️ Cleared \(expiredQuotes.count) expired quote caches")
            }
        }
        
        // Clear price history older than 1 hour
        let historyDescriptor = FetchDescriptor<CachedPriceHistory>()
        if let histories = try? context.fetch(historyDescriptor) {
            let expiredHistories = histories.filter { Date().timeIntervalSince($0.timestamp) > 3600 }
            expiredHistories.forEach { context.delete($0) }
            if !expiredHistories.isEmpty {
                print("🗑️ Cleared \(expiredHistories.count) expired price history caches")
            }
        }
        
        try? context.save()
    }
    
    // MARK: - AI Analysis Cache
    
    func getCachedAnalysis(ticker: String, provider: AIProvider, type: AIAnalysisType, maxAge: TimeInterval = 3600) -> AIAnalysis? {
        let context = ModelContext(modelContainer)
        
        let id = "\(ticker)-\(provider.rawValue)-\(type.rawValue)"
        let predicate = #Predicate<CachedAIAnalysis> { $0.id == id }
        let descriptor = FetchDescriptor<CachedAIAnalysis>(predicate: predicate)
        
        guard let cached = try? context.fetch(descriptor).first else {
            return nil
        }
        
        // Check if cache is still valid
        let age = Date().timeIntervalSince(cached.timestamp)
        if age > maxAge {
            print("⏰ AI analysis cache expired for \(ticker)-\(provider.rawValue)-\(type.rawValue) (age: \(Int(age))s)")
            return nil
        }
        
        print("✅ Using cached AI analysis for \(ticker)-\(provider.rawValue)-\(type.rawValue) (age: \(Int(age))s)")
        return cached.analysis
    }
    
    func cacheAnalysis(ticker: String, provider: AIProvider, type: AIAnalysisType, analysis: AIAnalysis) {
        let context = ModelContext(modelContainer)
        
        let id = "\(ticker)-\(provider.rawValue)-\(type.rawValue)"
        let predicate = #Predicate<CachedAIAnalysis> { $0.id == id }
        let descriptor = FetchDescriptor<CachedAIAnalysis>(predicate: predicate)
        
        // Delete existing cache
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
        
        // Insert new cache
        let cached = CachedAIAnalysis(ticker: ticker, provider: provider, analysisType: type, analysis: analysis)
        context.insert(cached)
        
        try? context.save()
        print("💾 Cached AI analysis for \(ticker)-\(provider.rawValue)-\(type.rawValue)")
    }
}
