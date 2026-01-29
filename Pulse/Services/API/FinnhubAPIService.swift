import Foundation

actor FinnhubAPIService: StockDataService {
    static let shared = FinnhubAPIService()
    
    private let baseURL = "https://api.finnhub.io/api/v1"
    private let networkManager = NetworkManager.shared
    private var apiKey: String {
        Constants.API.finnhubAPIKey
    }
    
    // Cache for stock data
    private var stockCache: [String: (stock: Stock, timestamp: Date)] = [:]
    private var priceDataCache: [String: (data: [PricePoint], timestamp: Date)] = [:]
    
    private init() {}
    
    // MARK: - StockDataService Protocol
    
    /// Get current stock quote with daily data
    func getStockQuote(ticker: String) async throws -> Stock {
        // Check cache first
        if let cached = stockCache[ticker],
           Date().timeIntervalSince(cached.timestamp) < Constants.Cache.stockDataCacheDuration {
            return cached.stock
        }
        
        guard !apiKey.isEmpty else {
            print("❌ FINNHUB: API key is empty!")
            throw APIError.missingAPIKey
        }
        
        print("✅ FINNHUB: Using API key: \(String(apiKey.prefix(10)))...")
        
        // Finnhub quote endpoint
        guard let url = URL(string: "\(baseURL)/quote?symbol=\(ticker)&token=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: FinnhubQuoteResponse = try await networkManager.request(url: url)
        
        // Calculate daily change
        let dailyChange = response.c - response.pc
        let dailyChangePercent = (dailyChange / response.pc) * 100
        
        let stock = Stock(
            ticker: ticker,
            companyName: ticker, // Will fetch company name separately
            currentPrice: response.c,
            dailyChange: dailyChange,
            dailyChangePercent: dailyChangePercent,
            volume: Int(response.v ?? 0),
            previousClose: response.pc,
            openPrice: response.o,
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
        
        // Finnhub uses Unix timestamps
        let fromTimestamp = Int(from.timeIntervalSince1970)
        let toTimestamp = Int(to.timeIntervalSince1970)
        
        // Use daily resolution for historical data
        guard let url = URL(string: "\(baseURL)/stock/candle?symbol=\(ticker)&resolution=D&from=\(fromTimestamp)&to=\(toTimestamp)&token=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: FinnhubCandleResponse = try await networkManager.request(url: url)
        
        // Check if data is available
        guard response.s == "ok", !response.t.isEmpty else {
            throw APIError.invalidData
        }
        
        // Convert to PricePoint array
        var pricePoints: [PricePoint] = []
        for i in 0..<response.t.count {
            let pricePoint = PricePoint(
                date: Date(timeIntervalSince1970: TimeInterval(response.t[i])),
                open: response.o[i],
                high: response.h[i],
                low: response.l[i],
                close: response.c[i],
                volume: Int(response.v[i])
            )
            pricePoints.append(pricePoint)
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
        
        guard let url = URL(string: "\(baseURL)/search?q=\(query)&token=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: FinnhubSearchResponse = try await networkManager.request(url: url)
        
        return response.result.map { result in
            StockSearchResult(
                ticker: result.symbol,
                name: result.description
            )
        }
    }
    
    /// Get detailed stock information
    func getStockDetails(ticker: String) async throws -> Stock {
        // MOCK MODE: Return sample data
        if Constants.API.useMockData {
            print("🎭 MOCK MODE: Returning sample data for \(ticker)")
            return Stock.samples.first { $0.ticker == ticker } ?? Stock.sample
        }
        
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        // Get basic quote first
        var stock = try await getStockQuote(ticker: ticker)
        
        // Get company profile for additional details
        guard let profileURL = URL(string: "\(baseURL)/stock/profile2?symbol=\(ticker)&token=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let profile: FinnhubProfileResponse = try await networkManager.request(url: profileURL)
        
        // Update stock with additional details
        stock = Stock(
            id: stock.id,
            ticker: stock.ticker,
            companyName: profile.name,
            currentPrice: stock.currentPrice,
            dailyChange: stock.dailyChange,
            dailyChangePercent: stock.dailyChangePercent,
            postMarketChange: stock.postMarketChange,
            postMarketChangePercent: stock.postMarketChangePercent,
            volume: stock.volume,
            avgVolume: stock.avgVolume,
            marketCap: profile.marketCapitalization,
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

// MARK: - Finnhub Response Models

private struct FinnhubQuoteResponse: Codable {
    let c: Double  // Current price
    let d: Double? // Change
    let dp: Double? // Percent change
    let h: Double  // High price of the day
    let l: Double  // Low price of the day
    let o: Double  // Open price of the day
    let pc: Double // Previous close price
    let t: Int?    // Timestamp
    let v: Double? // Volume
}

private struct FinnhubCandleResponse: Codable {
    let c: [Double] // Close prices
    let h: [Double] // High prices
    let l: [Double] // Low prices
    let o: [Double] // Open prices
    let s: String   // Status (ok or no_data)
    let t: [Int]    // Timestamps
    let v: [Double] // Volumes
}

private struct FinnhubSearchResponse: Codable {
    let count: Int
    let result: [FinnhubSearchResult]
}

private struct FinnhubSearchResult: Codable {
    let description: String
    let displaySymbol: String
    let symbol: String
    let type: String
}

private struct FinnhubProfileResponse: Codable {
    let country: String
    let currency: String
    let exchange: String
    let ipo: String?
    let marketCapitalization: Double
    let name: String
    let phone: String?
    let shareOutstanding: Double
    let ticker: String
    let weburl: String?
    let logo: String?
    let finnhubIndustry: String?
}
