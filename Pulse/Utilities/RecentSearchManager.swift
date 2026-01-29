import Foundation
import Combine

class RecentSearchManager: ObservableObject {
    @Published private(set) var recentSearches: [StockSearchResult] = []
    
    private let maxRecentSearches = 15
    private let userDefaultsKey = "recentStockSearches"
    
    init() {
        loadRecentSearches()
    }
    
    func addSearch(_ result: StockSearchResult) {
        // Remove if already exists
        recentSearches.removeAll { $0.ticker == result.ticker }
        
        // Add to beginning
        recentSearches.insert(result, at: 0)
        
        // Limit to max
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        saveRecentSearches()
    }
    
    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }
    
    private func saveRecentSearches() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([StockSearchResult].self, from: data) {
            recentSearches = decoded
        }
    }
}
