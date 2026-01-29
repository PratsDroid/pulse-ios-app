import Foundation

actor AIServiceManager {
    static let shared = AIServiceManager()
    
    private let appleIntelligence = AppleIntelligenceService.shared
    private let gemini = GeminiAIService.shared
    
    private init() {}
    
    // MARK: - Provider Selection
    
    /// Get the best available AI service based on availability and configuration
    func getService() -> (any AIService, AIProvider) {
        // 1. Check if mock mode is enabled
        if Constants.API.useMockData {
            print("🎭 Using Mock AI (mock mode enabled)")
            return (gemini, .mock)  // Gemini has mock support built-in
        }
        
        // 2. Try Apple Intelligence first (privacy-first, offline capable)
        if AppleIntelligenceService.isAvailable() {
            print("🧠 Using Apple Intelligence (on-device)")
            return (appleIntelligence, .appleIntelligence)
        }
        
        // 3. Fall back to Gemini if API key exists
        if !Constants.API.geminiAPIKey.isEmpty {
            print("✨ Using Gemini AI (cloud-powered)")
            return (gemini, .gemini)
        }
        
        // 4. Final fallback to mock mode
        print("🎭 Using Mock AI (fallback)")
        return (gemini, .mock)
    }
    
    // MARK: - Convenience Methods
    
    
    func analyzeStock(stock: Stock, priceHistory: [PricePoint], type: AIAnalysisType = .general) async throws -> AIAnalysis {
        let (service, provider) = getService()
        print("📊 Analyzing \(stock.ticker) with \(provider.rawValue)...")
        
        do {
            var analysis = try await service.analyzeStock(stock: stock, priceHistory: priceHistory, type: type)
            
            // Ensure provider is set correctly (in case service doesn't set it)
            if analysis.provider != provider {
                analysis = AIAnalysis(
                    summary: analysis.summary,
                    sentiment: analysis.sentiment,
                    keyPoints: analysis.keyPoints,
                    patterns: analysis.patterns,
                    technicalLevels: analysis.technicalLevels,
                    recommendation: analysis.recommendation,
                    confidence: analysis.confidence,
                    provider: provider
                )
            }
            
            print("✅ Analysis complete using \(provider.rawValue)")
            return analysis
        } catch {
            print("❌ \(provider.rawValue) failed: \(error.localizedDescription)")
            
            // Try fallback if primary service fails
            if provider == .appleIntelligence {
                print("🔄 Falling back to Gemini AI...")
                return try await gemini.analyzeStock(stock: stock, priceHistory: priceHistory, type: type)
            }
            
            throw error
        }
    }
}
