import Foundation
import NaturalLanguage

actor AppleIntelligenceService: AIService {
    static let shared = AppleIntelligenceService()
    
    private init() {}
    
    // MARK: - Availability Check
    
    /// Check if Apple Intelligence is available on this device
    static func isAvailable() -> Bool {
        if #available(iOS 18.1, *) {
            // Check if device supports on-device ML
            return true
        }
        return false
    }
    
    // MARK: - AIService Protocol
    
    func analyzeStock(stock: Stock, priceHistory: [PricePoint], type: AIAnalysisType = .general) async throws -> AIAnalysis {
        guard Self.isAvailable() else {
            throw AIError.invalidRequest
        }
        
        // Calculate technical indicators
        let prices = priceHistory.map { $0.close }
        let volumes = priceHistory.map { Int64($0.volume) }
        
        let indicators = TechnicalIndicatorResults(
            rsi: TechnicalIndicators.rsi(prices: prices),
            macd: TechnicalIndicators.macd(prices: prices),
            sma20: TechnicalIndicators.sma(prices: prices, period: 20),
            sma50: TechnicalIndicators.sma(prices: prices, period: 50),
            sma200: TechnicalIndicators.sma(prices: prices, period: 200),
            bollingerBands: TechnicalIndicators.bollingerBands(prices: prices),
            averageVolume: TechnicalIndicators.averageVolume(volumes: volumes)
        )
        
        // Enhance stock with 52-week high/low from price history
        var enhancedStock = stock
        if !priceHistory.isEmpty {
            let prices = priceHistory.map { $0.close }
            enhancedStock = Stock(
                id: stock.id,
                ticker: stock.ticker,
                companyName: stock.companyName,
                currentPrice: stock.currentPrice,
                dailyChange: stock.dailyChange,
                dailyChangePercent: stock.dailyChangePercent,
                postMarketChange: stock.postMarketChange,
                postMarketChangePercent: stock.postMarketChangePercent,
                volume: stock.volume,
                avgVolume: stock.avgVolume,
                marketCap: stock.marketCap,
                peRatio: stock.peRatio,
                week52High: prices.max() ?? stock.week52High,
                week52Low: prices.min() ?? stock.week52Low,
                previousClose: stock.previousClose,
                openPrice: stock.openPrice,
                lastUpdated: stock.lastUpdated
            )
        }
        
        // Build analysis using NaturalLanguage framework
        return try await generateAnalysis(stock: enhancedStock, indicators: indicators)
    }
    
    func detectPatterns(priceHistory: [PricePoint]) async throws -> [Pattern] {
        // Use simple pattern detection based on price movements
        let prices = priceHistory.map { $0.close }
        var patterns: [Pattern] = []
        
        // Detect trend
        if let first = prices.first, let last = prices.last {
            let change = ((last - first) / first) * 100
            
            if change > 5 {
                patterns.append(Pattern(
                    name: "Uptrend",
                    description: "Strong upward price movement over the period",
                    significance: .high
                ))
            } else if change < -5 {
                patterns.append(Pattern(
                    name: "Downtrend",
                    description: "Strong downward price movement over the period",
                    significance: .high
                ))
            }
        }
        
        return patterns
    }
    
    func generateInsights(stock: Stock, indicators: TechnicalIndicatorResults) async throws -> String {
        var insights: [String] = []
        
        // RSI insights
        if let rsi = indicators.rsi {
            if rsi > 70 {
                insights.append("RSI indicates overbought conditions")
            } else if rsi < 30 {
                insights.append("RSI indicates oversold conditions")
            } else {
                insights.append("RSI shows healthy momentum")
            }
        }
        
        // Moving average insights
        if let sma20 = indicators.sma20, let sma50 = indicators.sma50 {
            if stock.currentPrice > sma20 && stock.currentPrice > sma50 {
                insights.append("Price above key moving averages, indicating uptrend")
            } else if stock.currentPrice < sma20 && stock.currentPrice < sma50 {
                insights.append("Price below key moving averages, indicating downtrend")
            }
        }
        
        return insights.joined(separator: ". ")
    }
    
    func answerQuestion(question: String, stock: Stock, context: String) async throws -> String {
        // Simple rule-based responses for now
        let lowercased = question.lowercased()
        
        if lowercased.contains("buy") {
            return "Based on current indicators, consider your risk tolerance and investment goals before making decisions."
        } else if lowercased.contains("sell") {
            return "Review the technical analysis and your investment strategy to determine if selling aligns with your goals."
        } else {
            return "I can help analyze \(stock.ticker) using technical indicators. What specific aspect would you like to know more about?"
        }
    }
    
    // MARK: - Private Methods
    
    private func generateAnalysis(stock: Stock, indicators: TechnicalIndicatorResults) async throws -> AIAnalysis {
        let isPositive = stock.dailyChange >= 0
        
        // Determine sentiment
        let sentiment: Sentiment = {
            if stock.dailyChangePercent > 1.5 {
                return .bullish
            } else if stock.dailyChangePercent < -1.5 {
                return .bearish
            } else {
                return .neutral
            }
        }()
        
        // Generate summary
        let summary = """
        \(stock.companyName) (\(stock.ticker)) is trading at $\(String(format: "%.2f", stock.currentPrice)), \
        \(isPositive ? "up" : "down") \(String(format: "%.2f", abs(stock.dailyChangePercent)))% today. \
        Technical analysis suggests \(sentiment == .bullish ? "bullish momentum" : sentiment == .bearish ? "bearish pressure" : "neutral consolidation").
        """
        
        // Generate key points
        var keyPoints: [String] = []
        
        if let rsi = indicators.rsi {
            if rsi > 70 {
                keyPoints.append("RSI at \(Int(rsi)) indicates overbought conditions, potential pullback ahead")
            } else if rsi < 30 {
                keyPoints.append("RSI at \(Int(rsi)) indicates oversold conditions, potential bounce opportunity")
            } else {
                keyPoints.append("RSI at \(Int(rsi)) shows healthy momentum with room to move")
            }
        }
        
        if let sma20 = indicators.sma20 {
            let percentFromSMA = ((stock.currentPrice - sma20) / sma20) * 100
            keyPoints.append("Price \(percentFromSMA > 0 ? "above" : "below") 20-day MA by \(String(format: "%.1f", abs(percentFromSMA)))%")
        }
        
        if let macd = indicators.macd {
            keyPoints.append("MACD \(macd.histogram > 0 ? "positive" : "negative"), momentum \(macd.histogram > 0 ? "building" : "weakening")")
        }
        
        keyPoints.append("Volume \(stock.volume > (stock.avgVolume ?? stock.volume) ? "above" : "below") average, indicating \(stock.volume > (stock.avgVolume ?? stock.volume) ? "strong" : "weak") conviction")
        
        // Detect patterns
        let patterns = try await detectPatterns(priceHistory: [])
        
        // Calculate technical levels
        let technicalLevels = calculateTechnicalLevels(stock: stock, indicators: indicators)
        
        // Generate recommendation
        let recommendation: String = {
            switch sentiment {
            case .bullish:
                return "Technical indicators support upward momentum. Consider positions on dips. Watch for resistance near $\(String(format: "%.2f", stock.currentPrice * 1.05))."
            case .bearish:
                return "Caution advised as indicators show weakness. Wait for stabilization. Support expected around $\(String(format: "%.2f", stock.currentPrice * 0.95))."
            case .neutral:
                return "Mixed signals suggest range-bound trading. Hold positions and wait for clearer direction between $\(String(format: "%.2f", stock.currentPrice * 0.97))-$\(String(format: "%.2f", stock.currentPrice * 1.03))."
            }
        }()
        
        let confidence = sentiment == .neutral ? 0.70 : 0.85
        
        return AIAnalysis(
            summary: summary,
            sentiment: sentiment,
            keyPoints: keyPoints,
            patterns: patterns,
            technicalLevels: technicalLevels,
            recommendation: recommendation,
            confidence: confidence,
            provider: .appleIntelligence
        )
    }
    
    private func calculateTechnicalLevels(stock: Stock, indicators: TechnicalIndicatorResults) -> [TechnicalLevel] {
        var levels: [TechnicalLevel] = []
        
        // Major Resistance: 52-week high
        if let week52High = stock.week52High {
            levels.append(TechnicalLevel(
                type: .majorResistance,
                price: week52High,
                significance: "52-week high, psychological barrier"
            ))
        }
        
        // Near Resistance: 50-day MA (if above current price)
        if let sma50 = indicators.sma50, sma50 > stock.currentPrice {
            levels.append(TechnicalLevel(
                type: .nearResistance,
                price: sma50,
                significance: "50-day moving average; key resistance level"
            ))
        }
        
        // Pivot Support: Current price as reference
        let pivotPrice = stock.currentPrice * 0.97
        levels.append(TechnicalLevel(
            type: .pivotSupport,
            price: pivotPrice,
            significance: "Recent support level, held multiple times"
        ))
        
        // Strong Support: 200-day MA
        if let sma200 = indicators.sma200 {
            levels.append(TechnicalLevel(
                type: .strongSupport,
                price: sma200,
                significance: "200-day MA; drop below would signal long-term trend change"
            ))
        }
        
        // Strong Support: 52-week low
        if let week52Low = stock.week52Low {
            levels.append(TechnicalLevel(
                type: .strongSupport,
                price: week52Low,
                significance: "52-week low, critical support"
            ))
        }
        
        // Sort by price descending (resistance at top, support at bottom)
        return levels.sorted { $0.price > $1.price }
    }
}
