import Foundation

struct Stock: Codable, Identifiable, Hashable {
    let id: UUID
    let ticker: String
    let companyName: String
    var currentPrice: Double
    var dailyChange: Double
    var dailyChangePercent: Double
    var postMarketChange: Double?
    var postMarketChangePercent: Double?
    var volume: Int
    var avgVolume: Int?
    var marketCap: Double?
    var peRatio: Double?
    var week52High: Double?
    var week52Low: Double?
    var previousClose: Double?
    var openPrice: Double?
    var lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        ticker: String,
        companyName: String,
        currentPrice: Double,
        dailyChange: Double,
        dailyChangePercent: Double,
        postMarketChange: Double? = nil,
        postMarketChangePercent: Double? = nil,
        volume: Int,
        avgVolume: Int? = nil,
        marketCap: Double? = nil,
        peRatio: Double? = nil,
        week52High: Double? = nil,
        week52Low: Double? = nil,
        previousClose: Double? = nil,
        openPrice: Double? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.ticker = ticker
        self.companyName = companyName
        self.currentPrice = currentPrice
        self.dailyChange = dailyChange
        self.dailyChangePercent = dailyChangePercent
        self.postMarketChange = postMarketChange
        self.postMarketChangePercent = postMarketChangePercent
        self.volume = volume
        self.avgVolume = avgVolume
        self.marketCap = marketCap
        self.peRatio = peRatio
        self.week52High = week52High
        self.week52Low = week52Low
        self.previousClose = previousClose
        self.openPrice = openPrice
        self.lastUpdated = lastUpdated
    }
    
    var isPositive: Bool {
        dailyChange >= 0
    }
    
    var isMarketOpen: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let weekday = calendar.component(.weekday, from: Date())
        
        // Simple check: Monday-Friday, 9:30 AM - 4:00 PM ET
        // Note: This is simplified and doesn't account for holidays
        return weekday >= 2 && weekday <= 6 && hour >= 9 && hour < 16
    }
}

// MARK: - Sample Data
extension Stock {
    static let sample = Stock(
        ticker: "AAPL",
        companyName: "Apple Inc.",
        currentPrice: 182.52,
        dailyChange: 2.34,
        dailyChangePercent: 1.30,
        volume: 52_430_000,
        avgVolume: 58_000_000,
        marketCap: 2_850_000_000_000,
        peRatio: 29.5,
        week52High: 199.62,
        week52Low: 164.08,
        previousClose: 180.18,
        openPrice: 180.50
    )
    
    static let samples: [Stock] = [
        Stock(
            ticker: "AAPL",
            companyName: "Apple Inc.",
            currentPrice: 182.52,
            dailyChange: 2.34,
            dailyChangePercent: 1.30,
            volume: 52_430_000,
            avgVolume: 58_000_000,
            marketCap: 2_850_000_000_000,
            peRatio: 29.5,
            week52High: 199.62,
            week52Low: 164.08,
            previousClose: 180.18,
            openPrice: 180.50
        ),
//        Stock(
//            ticker: "GOOGL",
//            companyName: "Alphabet Inc.",
//            currentPrice: 142.87,
//            dailyChange: -1.23,
//            dailyChangePercent: -0.85,
//            volume: 28_540_000,
//            avgVolume: 25_000_000,
//            marketCap: 1_780_000_000_000,
//            peRatio: 25.3,
//            week52High: 153.78,
//            week52Low: 121.46,
//            previousClose: 144.10,
//            openPrice: 143.80
//        ),
//        Stock(
//            ticker: "MSFT",
//            companyName: "Microsoft Corporation",
//            currentPrice: 415.26,
//            dailyChange: 5.67,
//            dailyChangePercent: 1.38,
//            volume: 22_340_000,
//            avgVolume: 24_000_000,
//            marketCap: 3_090_000_000_000,
//            peRatio: 35.8,
//            week52High: 430.82,
//            week52Low: 362.90,
//            previousClose: 409.59,
//            openPrice: 410.25
//        ),
//        Stock(
//            ticker: "NVDA",
//            companyName: "NVIDIA Corporation",
//            currentPrice: 875.28,
//            dailyChange: 12.45,
//            dailyChangePercent: 1.44,
//            volume: 45_670_000,
//            avgVolume: 50_000_000,
//            marketCap: 2_160_000_000_000,
//            peRatio: 68.2,
//            week52High: 974.27,
//            week52Low: 405.23,
//            previousClose: 862.83,
//            openPrice: 865.50
//        ),
//        Stock(
//            ticker: "TSLA",
//            companyName: "Tesla, Inc.",
//            currentPrice: 207.83,
//            dailyChange: -3.21,
//            dailyChangePercent: -1.52,
//            volume: 98_230_000,
//            avgVolume: 110_000_000,
//            marketCap: 660_000_000_000,
//            peRatio: 65.4,
//            week52High: 299.29,
//            week52Low: 138.80,
//            previousClose: 211.04,
//            openPrice: 210.50
//        )
    ]
}
