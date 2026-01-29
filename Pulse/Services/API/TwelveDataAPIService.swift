import Foundation

actor TwelveDataAPIService: StockDataService {
    static let shared = TwelveDataAPIService()
    
    private let baseURL = "https://api.twelvedata.com"
    private let networkManager = NetworkManager.shared
    private var apiKey: String {
        Constants.API.twelveDataAPIKey
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
            print("❌ TWELVE DATA: API key is empty!")
            throw APIError.missingAPIKey
        }
        
        print("✅ TWELVE DATA: Fetching quote for \(ticker)")
        
        // Twelve Data quote endpoint
        guard let url = URL(string: "\(baseURL)/quote?symbol=\(ticker)&apikey=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: TwelveDataQuoteResponse = try await networkManager.request(url: url)
        
        // Calculate daily change
        let currentPrice = Double(response.close) ?? 0
        let previousClose = Double(response.previous_close) ?? currentPrice
        let dailyChange = currentPrice - previousClose
        let dailyChangePercent = previousClose > 0 ? (dailyChange / previousClose) * 100 : 0
        
        let stock = Stock(
            ticker: ticker,
            companyName: response.name ?? ticker,
            currentPrice: currentPrice,
            dailyChange: dailyChange,
            dailyChangePercent: dailyChangePercent,
            volume: Int(response.volume ?? "0") ?? 0,
            previousClose: previousClose,
            openPrice: Double(response.open) ?? currentPrice,
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
        
        print("✅ TWELVE DATA: Fetching historical data for \(ticker)")
        
        // Calculate number of days for outputsize
        let days = Calendar.current.dateComponents([.day], from: from, to: to).day ?? 30
        let outputSize = min(days + 5, 5000) // Max 5000 data points on free tier
        
        // Twelve Data time series endpoint
        guard let url = URL(string: "\(baseURL)/time_series?symbol=\(ticker)&interval=1day&outputsize=\(outputSize)&apikey=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: TwelveDataTimeSeriesResponse = try await networkManager.request(url: url)
        
        // Check if data is available
        guard let values = response.values, !values.isEmpty else {
            throw APIError.invalidData
        }
        
        // Convert to PricePoint array
        var pricePoints: [PricePoint] = []
        for value in values {
            guard let datetime = value.datetime,
                  let open = Double(value.open),
                  let high = Double(value.high),
                  let low = Double(value.low),
                  let close = Double(value.close) else {
                print("⚠️ TWELVE DATA: Skipping invalid data point")
                continue
            }
            
            // Parse date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let date = dateFormatter.date(from: datetime) else {
                print("⚠️ TWELVE DATA: Failed to parse date: \(datetime)")
                continue
            }
            
            let pricePoint = PricePoint(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: Int(value.volume ?? "0") ?? 0
            )
            pricePoints.append(pricePoint)
        }
        
        print("✅ TWELVE DATA: Parsed \(pricePoints.count) price points from \(values.count) values")
        
        // Sort by date (oldest first)
        pricePoints.sort { $0.date < $1.date }
        
        // Filter to requested date range
        let beforeFilter = pricePoints.count
        pricePoints = pricePoints.filter { $0.date >= from && $0.date <= to }
        print("✅ TWELVE DATA: After date filter: \(pricePoints.count) points (was \(beforeFilter))")
        
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
        
        guard let url = URL(string: "\(baseURL)/symbol_search?symbol=\(query)&apikey=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: TwelveDataSearchResponse = try await networkManager.request(url: url)
        
        guard let data = response.data else { return [] }
        
        return data.map { result in
            StockSearchResult(
                ticker: result.symbol,
                name: result.instrument_name ?? result.symbol
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
        
        // For Twelve Data, we'll just use the quote endpoint
        // as the free tier doesn't have extensive fundamental data
        return try await getStockQuote(ticker: ticker)
    }
    
    /// Clear cache
    func clearCache() {
        stockCache.removeAll()
        priceDataCache.removeAll()
    }
    
    // MARK: - Technical Indicators (Twelve Data Exclusive!)
    
    /// Get RSI (Relative Strength Index) from Twelve Data
    func getRSI(ticker: String, period: Int = 14) async throws -> [Double] {
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        guard let url = URL(string: "\(baseURL)/rsi?symbol=\(ticker)&interval=1day&time_period=\(period)&apikey=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: TwelveDataIndicatorResponse = try await networkManager.request(url: url)
        
        guard let values = response.values else { return [] }
        
        return values.compactMap { Double($0.rsi ?? "") }
    }
    
    /// Get MACD from Twelve Data
    func getMACD(ticker: String) async throws -> [(macd: Double, signal: Double, histogram: Double)] {
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }
        
        guard let url = URL(string: "\(baseURL)/macd?symbol=\(ticker)&interval=1day&apikey=\(apiKey)") else {
            throw APIError.invalidURL
        }
        
        let response: TwelveDataMACDResponse = try await networkManager.request(url: url)
        
        guard let values = response.values else { return [] }
        
        return values.compactMap { value in
            guard let macd = Double(value.macd ?? ""),
                  let signal = Double(value.macd_signal ?? ""),
                  let histogram = Double(value.macd_hist ?? "") else {
                return nil
            }
            return (macd: macd, signal: signal, histogram: histogram)
        }
    }
}

// MARK: - Twelve Data Response Models

private struct TwelveDataQuoteResponse: Codable {
    let symbol: String
    let name: String?
    let exchange: String?
    let currency: String?
    let datetime: String?
    let timestamp: Int?
    let open: String
    let high: String
    let low: String
    let close: String
    let volume: String?
    let previous_close: String
    let change: String?
    let percent_change: String?
    let average_volume: String?
    let fifty_two_week: FiftyTwoWeek?
    
    struct FiftyTwoWeek: Codable {
        let low: String?
        let high: String?
        let low_change: String?
        let high_change: String?
        let low_change_percent: String?
        let high_change_percent: String?
        let range: String?
    }
}

private struct TwelveDataTimeSeriesResponse: Codable {
    let meta: Meta?
    let values: [TimeSeriesValue]?
    let status: String?
    
    struct Meta: Codable {
        let symbol: String
        let interval: String
        let currency: String?
        let exchange_timezone: String?
        let exchange: String?
        let mic_code: String?
        let type: String?
    }
    
    struct TimeSeriesValue: Codable {
        let datetime: String?
        let open: String
        let high: String
        let low: String
        let close: String
        let volume: String?
    }
}

private struct TwelveDataSearchResponse: Codable {
    let data: [SearchResult]?
    let status: String?
    
    struct SearchResult: Codable {
        let symbol: String
        let instrument_name: String?
        let exchange: String?
        let mic_code: String?
        let exchange_timezone: String?
        let instrument_type: String?
        let country: String?
        let currency: String?
    }
}

private struct TwelveDataIndicatorResponse: Codable {
    let meta: Meta?
    let values: [IndicatorValue]?
    let status: String?
    
    struct Meta: Codable {
        let symbol: String
        let interval: String
        let indicator: Indicator?
        
        struct Indicator: Codable {
            let name: String?
            let time_period: Int?
        }
    }
    
    struct IndicatorValue: Codable {
        let datetime: String?
        let rsi: String?
    }
}

private struct TwelveDataMACDResponse: Codable {
    let meta: Meta?
    let values: [MACDValue]?
    let status: String?
    
    struct Meta: Codable {
        let symbol: String
        let interval: String
    }
    
    struct MACDValue: Codable {
        let datetime: String?
        let macd: String?
        let macd_signal: String?
        let macd_hist: String?
    }
}
