import Foundation

struct StockSearchResult: Codable, Identifiable {
    let id: UUID
    let ticker: String
    let name: String
    let market: String
    let locale: String
    let primaryExchange: String?
    let type: String
    let active: Bool
    
    init(
        id: UUID = UUID(),
        ticker: String,
        name: String,
        market: String = "stocks",
        locale: String = "us",
        primaryExchange: String? = nil,
        type: String = "CS",
        active: Bool = true
    ) {
        self.id = id
        self.ticker = ticker
        self.name = name
        self.market = market
        self.locale = locale
        self.primaryExchange = primaryExchange
        self.type = type
        self.active = active
    }
}
