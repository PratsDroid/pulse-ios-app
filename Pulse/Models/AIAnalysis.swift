import Foundation

// MARK: - Technical Levels

enum LevelType: String, Codable {
    case majorResistance = "Major Resistance"
    case nearResistance = "Near Resistance"
    case pivotSupport = "Pivot Support"
    case strongSupport = "Strong Support"
    case minorSupport = "Minor Support"
    case minorResistance = "Minor Resistance"
}

struct TechnicalLevel: Codable, Identifiable {
    let id = UUID()
    let type: LevelType
    let price: Double
    let significance: String
    
    enum CodingKeys: String, CodingKey {
        case type, price, significance
    }
}

// MARK: - Sentiment

enum Sentiment: String, Codable {
    case bullish
    case bearish
    case neutral
    
    var emoji: String {
        switch self {
        case .bullish: return "📈"
        case .bearish: return "📉"
        case .neutral: return "➡️"
        }
    }
    
    var color: String {
        switch self {
        case .bullish: return "green"
        case .bearish: return "red"
        case .neutral: return "gray"
        }
    }
    
    // Custom decoder to handle variations like "cautiously bullish"
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self).lowercased()
        
        // Map variations to base sentiments
        if rawValue.contains("bullish") {
            self = .bullish
        } else if rawValue.contains("bearish") {
            self = .bearish
        } else {
            self = .neutral
        }
    }
}

enum PatternSignificance: String, Codable {
    case high
    case medium
    case low
}

struct Pattern: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let significance: PatternSignificance
    
    enum CodingKeys: String, CodingKey {
        case name, description, significance
    }
}

struct AIAnalysis: Codable, Identifiable {
    let id: UUID
    let summary: String
    let sentiment: Sentiment
    let keyPoints: [String]
    let patterns: [Pattern]
    let technicalLevels: [TechnicalLevel]
    let recommendation: String
    let confidence: Double
    let provider: AIProvider
    let fetchedAt: Date
    
    init(
        id: UUID = UUID(),
        summary: String,
        sentiment: Sentiment,
        keyPoints: [String],
        patterns: [Pattern],
        technicalLevels: [TechnicalLevel],
        recommendation: String,
        confidence: Double,
        provider: AIProvider,
        fetchedAt: Date = Date()
    ) {
        self.id = id
        self.summary = summary
        self.sentiment = sentiment
        self.keyPoints = keyPoints
        self.patterns = patterns
        self.technicalLevels = technicalLevels
        self.recommendation = recommendation
        self.confidence = confidence
        self.provider = provider
        self.fetchedAt = fetchedAt
    }
}
