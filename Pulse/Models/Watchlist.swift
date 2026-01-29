import Foundation

struct Watchlist: Codable {
    var stocks: [Stock]
    var lastUpdated: Date
    
    init(stocks: [Stock] = [], lastUpdated: Date = Date()) {
        self.stocks = stocks
        self.lastUpdated = lastUpdated
    }
    
    mutating func addStock(_ stock: Stock) {
        if !stocks.contains(where: { $0.ticker == stock.ticker }) {
            stocks.append(stock)
            lastUpdated = Date()
        }
    }
    
    mutating func removeStock(ticker: String) {
        stocks.removeAll { $0.ticker == ticker }
        lastUpdated = Date()
    }
    
    mutating func updateStock(_ stock: Stock) {
        if let index = stocks.firstIndex(where: { $0.ticker == stock.ticker }) {
            stocks[index] = stock
            lastUpdated = Date()
        }
    }
    
    func contains(ticker: String) -> Bool {
        stocks.contains { $0.ticker == ticker }
    }
}
