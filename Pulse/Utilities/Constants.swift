import SwiftUI

enum Constants {
    // MARK: - API
    enum API {
        // TOGGLE THIS TO AVOID RATE LIMITS DURIN   G DEVELOPMENT
        static let useMockData = false  // Set to false to use real API
        
        static let polygonBaseURL = "https://api.polygon.io"
        static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta"
        
        // Fetch API key from Config.plist or environment variable
        static var polygonAPIKey: String {
            // Try to read from Config.plist first
            if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
               let config = NSDictionary(contentsOfFile: path),
               let key = config["POLYGON_API_KEY"] as? String {
                return key
            }
            // Fallback to environment variable
            return ProcessInfo.processInfo.environment["POLYGON_API_KEY"] ?? ""
        }
        
        static var geminiAPIKey: String {
            // Try to read from Config.plist first
            if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
               let config = NSDictionary(contentsOfFile: path),
               let key = config["GEMINI_API_KEY"] as? String {
                return key
            }
            // Fallback to environment variable
            return ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
        }
        
        static var finnhubAPIKey: String {
            // Try to read from Config.plist first
            if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
               let config = NSDictionary(contentsOfFile: path),
               let key = config["FINNHUB_API_KEY"] as? String {
                return key
            }
            // Fallback to environment variable
            return ProcessInfo.processInfo.environment["FINNHUB_API_KEY"] ?? ""
        }
        
        static var twelveDataAPIKey: String {
            // Try to read from Config.plist first
            if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
               let config = NSDictionary(contentsOfFile: path),
               let key = config["TWELVE_DATA_API_KEY"] as? String {
                return key
            }
            // Fallback to environment variable
            return ProcessInfo.processInfo.environment["TWELVE_DATA_API_KEY"] ?? ""
        }
    }
    
    // MARK: - Colors
    enum Colors {
        static let positiveGreen = Color(red: 0, green: 200/255, blue: 83/255)
        static let negativeRed = Color(red: 1, green: 23/255, blue: 68/255)
        static let backgroundDark = Color(red: 18/255, green: 18/255, blue: 18/255)
        static let cardBackground = Color(red: 28/255, green: 28/255, blue: 30/255)
        static let textPrimary = Color.white
        static let textSecondary = Color.gray
    }
    
    // MARK: - Formatting
    enum Format {
        static let priceFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter
        }()
        
        static let percentFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            formatter.positivePrefix = "+"
            return formatter
        }()
        
        static let largeNumberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }()
        
        static let compactNumberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            // Note: .notation is iOS 15+, using custom formatting instead
            formatter.maximumFractionDigits = 2
            return formatter
        }()
    }
    
    // MARK: - Chart Timeframes
    enum ChartTimeframe: String, CaseIterable {
        case oneDay = "1D"
        case fiveDays = "5D"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case yearToDate = "YTD"
        case oneYear = "1Y"
        case all = "ALL"
        
        var days: Int {
            switch self {
            case .oneDay: return 1
            case .fiveDays: return 5
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .yearToDate:
                let calendar = Calendar.current
                let now = Date()
                let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
                return calendar.dateComponents([.day], from: startOfYear, to: now).day ?? 365
            case .oneYear: return 365
            case .all: return 365 * 5 // 5 years
            }
        }
    }
    
    // MARK: - Cache
    enum Cache {
        static let stockDataCacheDuration: TimeInterval = 60 // 1 minute
        static let aiAnalysisCacheDuration: TimeInterval = 3600 // 1 hour
    }
    
    // MARK: - UI
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let spacing: CGFloat = 12
        static let animationDuration: Double = 0.3
    }
}
