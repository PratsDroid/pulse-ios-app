import Foundation
import Combine

@MainActor
class AIAnalysisViewModel: ObservableObject {
    @Published var analysis: AIAnalysis?
    @Published var isLoading = false
    @Published var error: AIError?
    @Published var showError = false
    @Published var selectedProvider: AIProvider
    @Published var analysisType: AIAnalysisType
    
    private let serviceManager = AIServiceManager.shared
    private let stock: Stock
    private var priceHistory: [PricePoint]
    
    // Cache analysis results per provider and type
    private var analysisCache: [AIProvider: [AIAnalysisType: AIAnalysis]] = [:]
    
    init(stock: Stock, priceHistory: [PricePoint], analysisType: AIAnalysisType = .general) {
        self.stock = stock
        self.priceHistory = priceHistory
        self.analysisType = analysisType
        
        // Set default provider based on availability
        if AppleIntelligenceService.isAvailable() {
            self.selectedProvider = .appleIntelligence
        } else if !Constants.API.geminiAPIKey.isEmpty {
            self.selectedProvider = .gemini
        } else {
            self.selectedProvider = .mock
        }
        
        // If price history is insufficient for technical analysis, fetch more
        Task {
            if priceHistory.count < 250 {
                print("⚠️ Insufficient price history (\(priceHistory.count) days), fetching 1 year of data...")
                await fetchExtendedPriceHistory()
            }
        }
    }
    
    func loadAnalysis(type: AIAnalysisType? = nil, forceProvider: AIProvider? = nil) async {
        let provider = forceProvider ?? selectedProvider
        let analysisType = type ?? self.analysisType
        
        // Check in-memory cache first
        if let cachedAnalysis = analysisCache[provider]?[analysisType] {
            print("📦 Using in-memory cached \(analysisType.rawValue) for \(provider.rawValue)")
            analysis = cachedAnalysis
            return
        }
        
        // Check database cache
        if let dbCached = await DataManager.shared.getCachedAnalysis(ticker: stock.ticker, provider: provider, type: analysisType, maxAge: 3600) {
            print("📦 Using database cached \(analysisType.rawValue) for \(provider.rawValue)")
            analysis = dbCached
            // Also store in memory cache
            if analysisCache[provider] == nil {
                analysisCache[provider] = [:]
            }
            analysisCache[provider]?[analysisType] = dbCached
            return
        }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            print("🔍 Starting \(analysisType.rawValue) for \(stock.ticker) with \(provider.rawValue)...")
            
            // Get specific service based on provider
            let service: any AIService
            switch provider {
            case .appleIntelligence:
                service = AppleIntelligenceService.shared
            case .gemini:
                service = GeminiAIService.shared
            case .mock:
                service = GeminiAIService.shared // Uses mock mode
            }
            
            let result = try await service.analyzeStock(stock: stock, priceHistory: priceHistory, type: analysisType)
            
            // Cache in memory
            if analysisCache[provider] == nil {
                analysisCache[provider] = [:]
            }
            analysisCache[provider]?[analysisType] = result
            
            // Cache in database
            await DataManager.shared.cacheAnalysis(ticker: stock.ticker, provider: provider, type: analysisType, analysis: result)
            
            analysis = result
            
            print("✅ \(analysisType.rawValue) completed successfully with \(provider.rawValue)")
            print("📊 Generated \(result.technicalLevels.count) technical levels")
        } catch let aiError as AIError {
            print("❌ AI Error: \(aiError.localizedDescription)")
            error = aiError
            showError = true
        } catch {
            print("❌ Unexpected error: \(error)")
            self.error = .networkError(error)
            showError = true
        }
    }
    
    func refresh() async {
        // Clear cache on refresh
        analysisCache.removeAll()
        await loadAnalysis()
    }
    
    private func fetchExtendedPriceHistory() async {
        let calendar = Calendar.current
        let to = Date()
        guard let from = calendar.date(byAdding: .day, value: -365, to: to) else {
            return
        }
        
        do {
            let apiService = StockDataServiceManager.shared
            let history = try await apiService.getHistoricalData(
                ticker: stock.ticker,
                from: from,
                to: to
            )
            self.priceHistory = history
            print("✅ Fetched \(history.count) days of price history for technical analysis")
        } catch {
            print("⚠️ Failed to fetch extended price history: \(error)")
            // Keep using the existing price history
        }
    }
}
