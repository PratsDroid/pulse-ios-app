import Foundation

protocol AIService {
    /// Analyze a stock with its price history
    func analyzeStock(stock: Stock, priceHistory: [PricePoint], type: AIAnalysisType) async throws -> AIAnalysis
    
    /// Detect chart patterns in price history
    func detectPatterns(priceHistory: [PricePoint]) async throws -> [Pattern]
    
    /// Generate insights based on stock and technical indicators
    func generateInsights(stock: Stock, indicators: TechnicalIndicatorResults) async throws -> String
    
    /// Answer a natural language question about a stock
    func answerQuestion(question: String, stock: Stock, context: String) async throws -> String
}

struct TechnicalIndicatorResults {
    let rsi: Double?
    let macd: TechnicalIndicators.MACDResult?
    let sma20: Double?
    let sma50: Double?
    let sma200: Double?
    let bollingerBands: TechnicalIndicators.BollingerBands?
    let averageVolume: Double?
}
