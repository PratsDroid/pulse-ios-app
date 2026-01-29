import Foundation

actor GeminiAIService: AIService {
    static let shared = GeminiAIService()
    
    private let model = "gemini-2.5-flash"  // Correct stable model name
    private let networkManager = NetworkManager.shared
    
    private var apiKey: String {
        Constants.API.geminiAPIKey
    }
    
    private init() {}
    
    // MARK: - AIService Protocol
    
    func analyzeStock(stock: Stock, priceHistory: [PricePoint], type: AIAnalysisType = .general) async throws -> AIAnalysis {
        // MOCK MODE: Return sample analysis to avoid API rate limits
        if Constants.API.useMockData {
            print("🎭 MOCK MODE: Returning sample AI analysis for \(stock.ticker)")
            return createMockAnalysis(for: stock)
        }
        
        guard !apiKey.isEmpty else {
            throw AIError.missingAPIKey
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
        
        // Build prompt based on analysis type
        let prompt: String
        switch type {
        case .general:
            prompt = buildAnalysisPrompt(stock: enhancedStock, indicators: indicators, priceHistory: priceHistory)
        case .monthForecast:
            prompt = buildMonthForecastPrompt(stock: enhancedStock, indicators: indicators, priceHistory: priceHistory)
        case .weekForecast:
            prompt = buildWeekForecastPrompt(stock: enhancedStock, indicators: indicators, priceHistory: priceHistory)
        }
        
        // Call Gemini API
        let response = try await generateContent(prompt: prompt)
        
        // Parse response
        var analysis = try parseAnalysisResponse(response)
        
        // Calculate technical levels (Gemini doesn't provide these)
        let technicalLevels = calculateTechnicalLevels(stock: enhancedStock, indicators: indicators)
        
        // Add technical levels to analysis
        analysis = AIAnalysis(
            summary: analysis.summary,
            sentiment: analysis.sentiment,
            keyPoints: analysis.keyPoints,
            patterns: analysis.patterns,
            technicalLevels: technicalLevels,
            recommendation: analysis.recommendation,
            confidence: analysis.confidence,
            provider: .gemini
        )
        
        return analysis
    }
    
    private func calculateTechnicalLevels(stock: Stock, indicators: TechnicalIndicatorResults) -> [TechnicalLevel] {
        var levels: [TechnicalLevel] = []
        let currentPrice = stock.currentPrice
        
        print("🔧 Calculating technical levels for \(stock.ticker)")
        print("   Current: $\(currentPrice)")
        print("   52w High: \(stock.week52High ?? 0)")
        print("   52w Low: \(stock.week52Low ?? 0)")
        print("   SMA20: \(indicators.sma20 ?? 0)")
        print("   SMA50: \(indicators.sma50 ?? 0)")
        print("   SMA200: \(indicators.sma200 ?? 0)")
        
        // RESISTANCE LEVELS
        
        // Major Resistance: 52-week high (if significantly above current)
        if let week52High = stock.week52High, week52High > currentPrice * 1.02 {
            let percentAway = ((week52High - currentPrice) / currentPrice) * 100
            levels.append(TechnicalLevel(
                type: .majorResistance,
                price: week52High,
                significance: "52-week high, \(String(format: "%.1f", percentAway))% above current price"
            ))
        }
        
        // Near Resistance: 200-day MA (if above current)
        if let sma200 = indicators.sma200, sma200 > currentPrice {
            levels.append(TechnicalLevel(
                type: .nearResistance,
                price: sma200,
                significance: "200-day moving average; long-term resistance"
            ))
        }
        
        // Near Resistance: 50-day MA (if above current)
        if let sma50 = indicators.sma50, sma50 > currentPrice {
            levels.append(TechnicalLevel(
                type: .nearResistance,
                price: sma50,
                significance: "50-day moving average; medium-term resistance"
            ))
        }
        
        // Immediate Resistance: Upper Bollinger Band
        if let bb = indicators.bollingerBands, bb.upper > currentPrice {
            levels.append(TechnicalLevel(
                type: .nearResistance,
                price: bb.upper,
                significance: "Upper Bollinger Band; immediate resistance zone"
            ))
        }
        
        // SUPPORT LEVELS
        
        // Immediate Support: 20-day MA (if below current)
        if let sma20 = indicators.sma20, sma20 < currentPrice {
            levels.append(TechnicalLevel(
                type: .pivotSupport,
                price: sma20,
                significance: "20-day moving average; short-term support"
            ))
        }
        
        // Immediate Support: Lower Bollinger Band
        if let bb = indicators.bollingerBands, bb.lower < currentPrice {
            levels.append(TechnicalLevel(
                type: .pivotSupport,
                price: bb.lower,
                significance: "Lower Bollinger Band; immediate support zone"
            ))
        }
        
        // Strong Support: 50-day MA (if below current)
        if let sma50 = indicators.sma50, sma50 < currentPrice {
            levels.append(TechnicalLevel(
                type: .strongSupport,
                price: sma50,
                significance: "50-day MA; key support level, held multiple times"
            ))
        }
        
        // Strong Support: 200-day MA (if below current)
        if let sma200 = indicators.sma200, sma200 < currentPrice {
            levels.append(TechnicalLevel(
                type: .strongSupport,
                price: sma200,
                significance: "200-day MA; critical long-term support"
            ))
        }
        
        // Strong Support: 52-week low (if significantly below current)
        if let week52Low = stock.week52Low, week52Low < currentPrice * 0.98 {
            let percentAway = ((currentPrice - week52Low) / currentPrice) * 100
            levels.append(TechnicalLevel(
                type: .strongSupport,
                price: week52Low,
                significance: "52-week low, \(String(format: "%.1f", percentAway))% below current price"
            ))
        }
        
        // ENSURE BALANCE: If we have resistance levels but no support, or vice versa, add calculated levels
        let resistanceLevels = levels.filter { $0.price > currentPrice }
        let supportLevels = levels.filter { $0.price < currentPrice }
        
        // If no resistance levels (stock at new highs), add calculated resistance
        if resistanceLevels.isEmpty {
            // Add near-term resistance targets
            levels.append(TechnicalLevel(
                type: .nearResistance,
                price: currentPrice * 1.02,
                significance: "Near-term resistance; 2% above current price"
            ))
            
            levels.append(TechnicalLevel(
                type: .majorResistance,
                price: currentPrice * 1.05,
                significance: "Major resistance; 5% extension target"
            ))
        }
        
        // If no support levels (stock at new lows), add calculated support
        if supportLevels.isEmpty {
            levels.append(TechnicalLevel(
                type: .pivotSupport,
                price: currentPrice * 0.98,
                significance: "Near-term support; 2% below current price"
            ))
            
            levels.append(TechnicalLevel(
                type: .strongSupport,
                price: currentPrice * 0.95,
                significance: "Strong support; 5% retracement level"
            ))
        }
        
        // Add psychological levels if we still have too few
        if levels.count < 4 {
            // Add psychological resistance (round number above)
            let resistancePrice = ceil(currentPrice / 10) * 10
            if resistancePrice > currentPrice && !levels.contains(where: { abs($0.price - resistancePrice) < 1.0 }) {
                levels.append(TechnicalLevel(
                    type: .nearResistance,
                    price: resistancePrice,
                    significance: "Psychological resistance at round number"
                ))
            }
            
            // Add psychological support (round number below)
            let supportPrice = floor(currentPrice / 10) * 10
            if supportPrice < currentPrice && !levels.contains(where: { abs($0.price - supportPrice) < 1.0 }) {
                levels.append(TechnicalLevel(
                    type: .pivotSupport,
                    price: supportPrice,
                    significance: "Psychological support at round number"
                ))
            }
        }
        
        // Sort by price descending (resistance at top, support at bottom)
        return levels.sorted { $0.price > $1.price }
    }
    
    func detectPatterns(priceHistory: [PricePoint]) async throws -> [Pattern] {
        guard !apiKey.isEmpty else {
            throw AIError.missingAPIKey
        }
        
        let prompt = buildPatternDetectionPrompt(priceHistory: priceHistory)
        let response = try await generateContent(prompt: prompt)
        
        return try parsePatterns(response)
    }
    
    func generateInsights(stock: Stock, indicators: TechnicalIndicatorResults) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.missingAPIKey
        }
        
        let prompt = buildInsightsPrompt(stock: stock, indicators: indicators)
        let response = try await generateContent(prompt: prompt)
        
        return response
    }
    
    func answerQuestion(question: String, stock: Stock, context: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.missingAPIKey
        }
        
        let prompt = """
        You are a financial analyst assistant. Answer this question about \(stock.ticker) (\(stock.companyName)):
        
        Question: \(question)
        
        Context:
        \(context)
        
        Provide a concise, helpful answer based on the data provided.
        """
        
        return try await generateContent(prompt: prompt)
    }
    
    // MARK: - Private Methods
    
    private func generateContent(prompt: String) async throws -> String {
        // Use v1beta API with gemini-1.5-pro model
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 8192  // Increased to prevent truncation
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        print("🌐 Calling Gemini API...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw AIError.invalidResponse
        }
        
        print("📡 Gemini API Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                print("⚠️ Rate limit exceeded")
                throw AIError.rateLimitExceeded
            }
            
            // Log error response
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ API Error Response: \(errorString)")
            }
            
            throw AIError.invalidResponse
        }
        
        // Parse Gemini response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(responseString.prefix(500))")
            }
            throw AIError.parsingError
        }
        
        print("✅ Parsed JSON response")
        
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            print("❌ Failed to extract text from response structure")
            print("📄 JSON keys: \(json.keys)")
            throw AIError.parsingError
        }
        
        print("✅ Extracted text response (\(text.count) chars)")
        return text
    }
    
    private func buildAnalysisPrompt(stock: Stock, indicators: TechnicalIndicatorResults, priceHistory: [PricePoint]) -> String {
        var prompt = """
        Analyze this stock and provide a structured analysis in JSON format.
        
        Stock: \(stock.ticker) (\(stock.companyName))
        Current Price: $\(stock.currentPrice.asCurrency)
        Daily Change: \(stock.dailyChangePercent.asPercentage) (\(stock.dailyChange >= 0 ? "+" : "")\(stock.dailyChange.asCurrency))
        52-Week Range: $\((stock.week52Low ?? 0).asCurrency) - $\((stock.week52High ?? 0).asCurrency)
        Market Cap: \((stock.marketCap ?? 0).asCompactNumber)
        
        Technical Indicators:
        """
        
        if let rsi = indicators.rsi {
            prompt += "\n- RSI (14): \(String(format: "%.2f", rsi))"
        }
        if let macd = indicators.macd {
            prompt += "\n- MACD: \(String(format: "%.2f", macd.macd)) (Signal: \(String(format: "%.2f", macd.signal)))"
        }
        if let sma20 = indicators.sma20 {
            prompt += "\n- 20-day SMA: $\(String(format: "%.2f", sma20))"
        }
        if let sma50 = indicators.sma50 {
            prompt += "\n- 50-day SMA: $\(String(format: "%.2f", sma50))"
        }
        
        prompt += """
        
        
        Respond ONLY with valid JSON in this exact format:
        {
          "summary": "Brief 2-3 sentence overview",
          "sentiment": "bullish" or "bearish" or "neutral",
          "keyPoints": ["point 1", "point 2", "point 3"],
          "patterns": [{"name": "pattern name", "description": "what it means", "significance": "high/medium/low"}],
          "recommendation": "Brief recommendation",
          "confidence": 0.85
        }
        """
        
        return prompt
    }
    
    private func buildMonthForecastPrompt(stock: Stock, indicators: TechnicalIndicatorResults, priceHistory: [PricePoint]) -> String {
        var prompt = """
        Provide a 1-MONTH TECHNICAL FORECAST for this stock in JSON format.
        
        Stock: \(stock.ticker) (\(stock.companyName))
        Current Price: $\(stock.currentPrice.asCurrency)
        Daily Change: \(stock.dailyChangePercent.asPercentage)
        52-Week Range: $\((stock.week52Low ?? 0).asCurrency) - $\((stock.week52High ?? 0).asCurrency)
        
        Technical Indicators:
        """
        
        if let rsi = indicators.rsi {
            prompt += "\n- RSI: \(String(format: "%.2f", rsi))"
        }
        if let macd = indicators.macd {
            prompt += "\n- MACD: \(String(format: "%.2f", macd.macd)) (Signal: \(String(format: "%.2f", macd.signal)))"
        }
        if let sma20 = indicators.sma20, let sma50 = indicators.sma50 {
            prompt += "\n- 20/50 SMA: $\(String(format: "%.2f", sma20)) / $\(String(format: "%.2f", sma50))"
        }
        
        prompt += """
        
        
        Focus on:
        - Monthly support/resistance zones
        - 30-day trend projection
        - Key price targets for the month
        - Potential breakout/breakdown levels
        
        Respond ONLY with valid JSON:
        {
          "summary": "2-3 sentence 30-day outlook",
          "sentiment": "bullish/bearish/neutral",
          "keyPoints": ["monthly insight 1", "monthly insight 2", "monthly insight 3"],
          "patterns": [{"name": "pattern", "description": "monthly significance", "significance": "high/medium/low"}],
          "recommendation": "30-day trading strategy",
          "confidence": 0.85
        }
        """
        
        return prompt
    }
    
    private func buildWeekForecastPrompt(stock: Stock, indicators: TechnicalIndicatorResults, priceHistory: [PricePoint]) -> String {
        var prompt = """
        Provide a 1-WEEK TECHNICAL FORECAST for this stock in JSON format.
        
        Stock: \(stock.ticker) (\(stock.companyName))
        Current Price: $\(stock.currentPrice.asCurrency)
        Daily Change: \(stock.dailyChangePercent.asPercentage)
        Volume: \(Double(stock.volume).asCompactNumber)
        
        Technical Indicators:
        """
        
        if let rsi = indicators.rsi {
            prompt += "\n- RSI: \(String(format: "%.2f", rsi))"
        }
        if let macd = indicators.macd {
            prompt += "\n- MACD: \(String(format: "%.2f", macd.macd))"
        }
        if let sma20 = indicators.sma20 {
            prompt += "\n- 20-day SMA: $\(String(format: "%.2f", sma20))"
        }
        if let bb = indicators.bollingerBands {
            prompt += "\n- Bollinger Bands: $\(String(format: "%.2f", bb.lower)) - $\(String(format: "%.2f", bb.upper))"
        }
        
        prompt += """
        
        
        Focus on:
        - Daily support/resistance levels
        - Short-term momentum (next 5-7 days)
        - Intraday volatility expectations
        - Immediate price targets
        
        Respond ONLY with valid JSON:
        {
          "summary": "2-3 sentence 7-day outlook",
          "sentiment": "bullish/bearish/neutral",
          "keyPoints": ["daily insight 1", "daily insight 2", "daily insight 3"],
          "patterns": [{"name": "pattern", "description": "short-term significance", "significance": "high/medium/low"}],
          "recommendation": "7-day trading strategy",
          "confidence": 0.85
        }
        """
        
        return prompt
    }
    
    private func buildPatternDetectionPrompt(priceHistory: [PricePoint]) -> String {
        let recentPrices = priceHistory.suffix(30).map { $0.close }
        
        return """
        Analyze these recent stock prices and detect chart patterns:
        \(recentPrices.map { String(format: "%.2f", $0) }.joined(separator: ", "))
        
        Respond with JSON array of patterns:
        [{"name": "pattern name", "description": "description", "significance": "high/medium/low"}]
        """
    }
    
    private func buildInsightsPrompt(stock: Stock, indicators: TechnicalIndicatorResults) -> String {
        return """
        Provide 3-5 key insights about \(stock.ticker) based on current price and technical indicators.
        Keep each insight to one sentence.
        """
    }
    
    private func parseAnalysisResponse(_ response: String) throws -> AIAnalysis {
        print("📝 Raw response length: \(response.count) chars")
        
        // Extract JSON from response - handle markdown code blocks
        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code block markers
        if jsonString.hasPrefix("```json") || jsonString.hasPrefix("```") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
            jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Find JSON object boundaries
        if let jsonStart = jsonString.range(of: "{"),
           let jsonEnd = jsonString.range(of: "}", options: .backwards) {
            // Safe substring extraction
            let startIndex = jsonStart.lowerBound
            let endIndex = jsonString.index(after: jsonEnd.lowerBound)
            if startIndex < endIndex && endIndex <= jsonString.endIndex {
                jsonString = String(jsonString[startIndex..<endIndex])
            }
        }
        
        print("📄 Cleaned JSON length: \(jsonString.count) chars")
        
        guard let data = jsonString.data(using: .utf8) else {
            print("❌ Failed to convert to data")
            throw AIError.parsingError
        }
        
        // Decode without technicalLevels first
        struct PartialAnalysis: Codable {
            let summary: String
            let sentiment: Sentiment
            let keyPoints: [String]
            let patterns: [Pattern]
            let recommendation: String
            let confidence: Double
        }
        
        let decoder = JSONDecoder()
        let partial = try decoder.decode(PartialAnalysis.self, from: data)
        
        // Return full analysis with empty technical levels (will be calculated separately)
        return AIAnalysis(
            summary: partial.summary,
            sentiment: partial.sentiment,
            keyPoints: partial.keyPoints,
            patterns: partial.patterns,
            technicalLevels: [],  // Will be added by caller if needed
            recommendation: partial.recommendation,
            confidence: partial.confidence,
            provider: .gemini
        )
    }
    
    private func parsePatterns(_ response: String) throws -> [Pattern] {
        var jsonString = response
        if let jsonStart = response.range(of: "["),
           let jsonEnd = response.range(of: "]", options: .backwards) {
            jsonString = String(response[jsonStart.lowerBound...jsonEnd.upperBound])
        }
        
        guard let data = jsonString.data(using: .utf8) else {
            throw AIError.parsingError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Pattern].self, from: data)
    }
    
    // MARK: - Mock Data Helper
    
    private func createMockAnalysis(for stock: Stock) -> AIAnalysis {
        let isPositive = stock.dailyChange >= 0
        
        let sentiment: Sentiment = {
            if stock.dailyChangePercent > 1.5 {
                return .bullish
            } else if stock.dailyChangePercent < -1.5 {
                return .bearish
            } else {
                return .neutral
            }
        }()
        
        let summary = """
        \(stock.companyName) (\(stock.ticker)) is currently trading at $\(String(format: "%.2f", stock.currentPrice)), \
        \(isPositive ? "up" : "down") \(String(format: "%.2f", abs(stock.dailyChangePercent)))% today. \
        The stock shows \(sentiment == .bullish ? "strong momentum" : sentiment == .bearish ? "weakness" : "consolidation") \
        with \(isPositive ? "buyers in control" : "selling pressure evident").
        """
        
        let keyPoints = [
            "Price is \(isPositive ? "above" : "below") key moving averages, indicating \(isPositive ? "uptrend" : "downtrend")",
            "Volume is \(stock.volume > (stock.avgVolume ?? stock.volume) ? "above" : "below") average, suggesting \(stock.volume > (stock.avgVolume ?? stock.volume) ? "strong" : "weak") conviction",
            "Market cap of \(formatMarketCap(stock.marketCap ?? 0)) positions it as a \(getMarketCapCategory(stock.marketCap ?? 0)) stock",
            isPositive ? "Momentum indicators suggest continuation potential" : "Support levels may provide buying opportunities"
        ]
        
        let patterns: [Pattern] = {
            if sentiment == .bullish {
                return [
                    Pattern(name: "Ascending Triangle", description: "Bullish continuation pattern suggesting upward breakout potential", significance: .high),
                    Pattern(name: "Golden Cross", description: "50-day MA crossing above 200-day MA, strong bullish signal", significance: .medium)
                ]
            } else if sentiment == .bearish {
                return [
                    Pattern(name: "Head and Shoulders", description: "Bearish reversal pattern indicating potential downside", significance: .high)
                ]
            } else {
                return [
                    Pattern(name: "Symmetrical Triangle", description: "Consolidation pattern, breakout direction uncertain", significance: .medium)
                ]
            }
        }()
        
        let recommendation = {
            switch sentiment {
            case .bullish:
                return "Consider accumulating on dips. Strong fundamentals support current valuation. Watch for resistance near $\(String(format: "%.2f", stock.currentPrice * 1.05))."
            case .bearish:
                return "Exercise caution. Wait for stabilization before entering. Support expected around $\(String(format: "%.2f", stock.currentPrice * 0.95))."
            case .neutral:
                return "Hold current positions. Wait for clearer directional signals. Range-bound trading likely between $\(String(format: "%.2f", stock.currentPrice * 0.97)) - $\(String(format: "%.2f", stock.currentPrice * 1.03))."
            }
        }()
        
        let confidence = sentiment == .neutral ? 0.65 : 0.82
        
        // Calculate technical levels
        let technicalLevels: [TechnicalLevel] = [
            stock.week52High.map { TechnicalLevel(type: .majorResistance, price: $0, significance: "52-week high, psychological barrier") },
            TechnicalLevel(type: .nearResistance, price: stock.currentPrice * 1.03, significance: "Recent resistance, needs volume to break"),
            TechnicalLevel(type: .pivotSupport, price: stock.currentPrice * 0.97, significance: "Immediate support level"),
            stock.week52Low.map { TechnicalLevel(type: .strongSupport, price: $0, significance: "52-week low, critical support") }
        ].compactMap { $0 }.sorted { $0.price > $1.price }
        
        return AIAnalysis(
            summary: summary,
            sentiment: sentiment,
            keyPoints: keyPoints,
            patterns: patterns,
            technicalLevels: technicalLevels,
            recommendation: recommendation,
            confidence: confidence,
            provider: .mock
        )
    }
    
    private func formatMarketCap(_ marketCap: Double) -> String {
        if marketCap >= 1_000_000_000_000 {
            return String(format: "$%.1fT", marketCap / 1_000_000_000_000)
        } else if marketCap >= 1_000_000_000 {
            return String(format: "$%.1fB", marketCap / 1_000_000_000)
        } else if marketCap >= 1_000_000 {
            return String(format: "$%.1fM", marketCap / 1_000_000)
        } else {
            return String(format: "$%.0f", marketCap)
        }
    }
    
    private func getMarketCapCategory(_ marketCap: Double) -> String {
        if marketCap >= 200_000_000_000 {
            return "mega-cap"
        } else if marketCap >= 10_000_000_000 {
            return "large-cap"
        } else if marketCap >= 2_000_000_000 {
            return "mid-cap"
        } else {
            return "small-cap"
        }
    }
}
