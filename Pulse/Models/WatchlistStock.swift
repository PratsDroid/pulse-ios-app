import Foundation
import SwiftData

@Model
class WatchlistStock {
    var ticker: String
    var companyName: String?
    var addedDate: Date
    var sortOrder: Int
    
    init(ticker: String, companyName: String? = nil, sortOrder: Int = 0) {
        self.ticker = ticker
        self.companyName = companyName
        self.addedDate = Date()
        self.sortOrder = sortOrder
    }
}
