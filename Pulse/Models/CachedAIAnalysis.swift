import Foundation
import SwiftData

/// Cached AI analysis result
@Model
final class CachedAIAnalysis {
    @Attribute(.unique) var id: String  // ticker-provider-type
    var ticker: String
    var provider: String  // AIProvider.rawValue
    var analysisType: String  // AIAnalysisType.rawValue
    var analysisData: Data  // JSON encoded AIAnalysis
    var timestamp: Date
    
    init(
        ticker: String,
        provider: AIProvider,
        analysisType: AIAnalysisType,
        analysis: AIAnalysis,
        timestamp: Date = Date()
    ) {
        self.ticker = ticker
        self.provider = provider.rawValue
        self.analysisType = analysisType.rawValue
        self.timestamp = timestamp
        self.id = "\(ticker)-\(provider.rawValue)-\(analysisType.rawValue)"
        
        // Encode analysis
        self.analysisData = (try? JSONEncoder().encode(analysis)) ?? Data()
    }
    
    /// Get decoded analysis
    var analysis: AIAnalysis? {
        try? JSONDecoder().decode(AIAnalysis.self, from: analysisData)
    }
}
