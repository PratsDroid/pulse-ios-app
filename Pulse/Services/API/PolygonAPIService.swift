import Foundation

actor PolygonAPIService: StockDataService {
    static let shared = PolygonAPIService()
    
    private let baseURL = Constants.API.polygonBaseURL
    private let networkManager = NetworkManager.shared
    private var apiKey: String {
        Constants.API.polygonAPIKey
    }
    
    // Cache for stock data
    private var stockCache: [String: (stock: Stock, timestamp: Date)] = [:]
    private var priceDataCache: [String: (data: [PricePoint], timestamp: Date)] = [:]
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Get current stock quote with daily data
    func getStockQuote(ticker: String) async throws -> Stock {
        // Check cache first
        if let cached = stockCache[ticker],
           Date().timeIntervalSince(cached.timestamp) < Constants.Cache.stockDataCacheDuration {
            return cached.stock
        }
        
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        // Polygon.io endpoint: /v2/aggs/ticker/{ticker}/prev
        guard let url = URL(string: "\(baseURL)/v2/aggs/ticker/\(ticker)/prev?apiKey=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: PolygonPreviousCloseResponse = try await networkManager.request(url: url)
        
        guard let result = response.results.first else {
            throw APIError.invalidData
        }
        
        let stock = Stock(
            ticker: response.ticker,
            companyName: ticker, // We'll need to fetch company name separately
            currentPrice: result.c,
            dailyChange: result.c - result.o,
            dailyChangePercent: ((result.c - result.o) / result.o) * 100,
            volume: result.v,
            previousClose: result.c,
            openPrice: result.o,
            lastUpdated: Date()
        )
        
        // Cache the result
        stockCache[ticker] = (stock, Date())
        
        return stock
    }
    
    /// Get historical price data for charts
    func getHistoricalData(
        ticker: String,
        from: Date,
        to: Date
    ) async throws -> [PricePoint] {
        // MOCK MODE: Return generated sample data
        if Constants.API.useMockData {
            print("🎭 MOCK MODE: Returning sample historical data for \(ticker)")
            let days = Calendar.current.dateComponents([.day], from: from, to: to).day ?? 30
            let basePrice = Stock.samples.first { $0.ticker == ticker }?.currentPrice ?? 150.0
            return PricePoint.generateSampleData(days: days, basePrice: basePrice)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cacheKey = "\(ticker)-\(formatter.string(from: from))-\(formatter.string(from: to))"
        
        // Check cache
        if let cached = priceDataCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < Constants.Cache.stockDataCacheDuration {
            return cached.data
        }
        
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        let fromString = formatter.string(from: from)
        let toString = formatter.string(from: to)
        
        // Use hourly aggregates for smoother charts (free tier supports this)
        // This gives ~6.5 points per day instead of 1, making charts much smoother
        guard let url = URL(string: "\(baseURL)/v2/aggs/ticker/\(ticker)/range/1/hour/\(fromString)/\(toString)?adjusted=true&sort=asc&apiKey=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: PolygonAggregatesResponse = try await networkManager.request(url: url)
        
        let pricePoints = response.results.map { result in
            PricePoint(
                date: Date(timeIntervalSince1970: TimeInterval(result.t) / 1000),
                open: result.o,
                high: result.h,
                low: result.l,
                close: result.c,
                volume: result.v
            )
        }
        
        // Cache the result
        priceDataCache[cacheKey] = (pricePoints, Date())
        
        return pricePoints
    }
    
    /// Search for stocks by ticker or company name
    func searchStocks(query: String) async throws -> [StockSearchResult] {
        // MOCK MODE: Search through sample stocks
        if Constants.API.useMockData {
            print("🎭 MOCK MODE: Searching sample stocks for '\(query)'")
            let lowercasedQuery = query.lowercased()
            return Stock.samples
                .filter { stock in
                    stock.ticker.lowercased().contains(lowercasedQuery) ||
                    stock.companyName.lowercased().contains(lowercasedQuery)
                }
                .map { StockSearchResult(ticker: $0.ticker, name: $0.companyName) }
        }
        
        guard !query.isEmpty else { return [] }
        
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        guard let url = URL(string: "\(baseURL)/v3/reference/tickers?search=\(query)&active=true&limit=10&apiKey=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: PolygonTickerSearchResponse = try await networkManager.request(url: url)
        
        return response.results.map { result in
            StockSearchResult(
                ticker: result.ticker,
                name: result.name,
                market: result.market,
                locale: result.locale,
                primaryExchange: result.primaryExchange,
                type: result.type,
                active: result.active
            )
        }
    }
    
    /// Get detailed stock information
    func getStockDetails(ticker: String) async throws -> Stock {
        // MOCK MODE: Return sample data to avoid API rate limits
        if Constants.API.useMockData {
            print("🎭 MOCK MODE: Returning sample data for \(ticker)")
            // Find matching sample or return first one
            return Stock.samples.first { $0.ticker == ticker } ?? Stock.sample
        }
        
        let cacheKey = "stock-\(ticker)"
        
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        // Get basic quote first
        var stock = try await getStockQuote(ticker: ticker)
        
        // Get ticker details for company name and other info
        guard let url = URL(string: "\(baseURL)/v3/reference/tickers/\(ticker)?apiKey=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: PolygonTickerDetailsResponse = try await networkManager.request(url: url)
        
        // Update stock with additional details
        stock = Stock(
            id: stock.id,
            ticker: stock.ticker,
            companyName: response.results.name,
            currentPrice: stock.currentPrice,
            dailyChange: stock.dailyChange,
            dailyChangePercent: stock.dailyChangePercent,
            postMarketChange: stock.postMarketChange,
            postMarketChangePercent: stock.postMarketChangePercent,
            volume: stock.volume,
            avgVolume: stock.avgVolume,
            marketCap: response.results.marketCap,
            peRatio: stock.peRatio,
            week52High: stock.week52High,
            week52Low: stock.week52Low,
            previousClose: stock.previousClose,
            openPrice: stock.openPrice,
            lastUpdated: stock.lastUpdated
        )
        
        return stock
    }
    
    /// Clear cache
    func clearCache() {
        stockCache.removeAll()
        priceDataCache.removeAll()
    }
}

// MARK: - Polygon.io Response Models

private struct PolygonPreviousCloseResponse: Codable {
    let ticker: String
    let queryCount: Int
    let resultsCount: Int
    let adjusted: Bool
    let results: [PolygonAggregateResult]
}

private struct PolygonAggregatesResponse: Codable {
    let ticker: String
    let queryCount: Int
    let resultsCount: Int
    let adjusted: Bool
    let results: [PolygonAggregateResult]
}

private struct PolygonAggregateResult: Codable {
    let v: Int      // Volume
    let vw: Double  // Volume weighted average price
    let o: Double   // Open
    let c: Double   // Close
    let h: Double   // High
    let l: Double   // Low
    let t: Int64    // Timestamp (milliseconds)
    let n: Int?     // Number of transactions
}

private struct PolygonTickerSearchResponse: Codable {
    let results: [PolygonTickerResult]
    let status: String
    let count: Int
}

private struct PolygonTickerResult: Codable {
    let ticker: String
    let name: String
    let market: String
    let locale: String
    let primaryExchange: String?
    let type: String
    let active: Bool
    let currencyName: String?
    let cik: String?
    let compositeFigi: String?
    let shareClassFigi: String?
}

private struct PolygonTickerDetailsResponse: Codable {
    let results: PolygonTickerDetails
    let status: String
}

private struct PolygonTickerDetails: Codable {
    let ticker: String
    let name: String
    let market: String
    let locale: String
    let primaryExchange: String?
    let type: String
    let active: Bool
    let currencyName: String?
    let cik: String?
    let compositeFigi: String?
    let shareClassFigi: String?
    let marketCap: Double?
    let phoneNumber: String?
    let address: PolygonAddress?
    let description: String?
    let sicCode: String?
    let sicDescription: String?
    let tickerRoot: String?
    let homepageUrl: String?
    let totalEmployees: Int?
    let listDate: String?
    let branding: PolygonBranding?
    let shareClassSharesOutstanding: Double?
    let weightedSharesOutstanding: Double?
}

private struct PolygonAddress: Codable {
    let address1: String?
    let city: String?
    let state: String?
    let postalCode: String?
}

private struct PolygonBranding: Codable {
    let logoUrl: String?
    let iconUrl: String?
}
