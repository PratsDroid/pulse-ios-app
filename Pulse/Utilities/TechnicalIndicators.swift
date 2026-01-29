import Foundation

/// Technical indicators calculator for stock analysis
struct TechnicalIndicators {
    
    // MARK: - Moving Averages
    
    /// Calculate Simple Moving Average
    static func sma(prices: [Double], period: Int) -> Double? {
        guard prices.count >= period else { return nil }
        let recentPrices = Array(prices.suffix(period))
        return recentPrices.reduce(0, +) / Double(period)
    }
    
    /// Calculate Exponential Moving Average
    static func ema(prices: [Double], period: Int) -> Double? {
        guard prices.count >= period else { return nil }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema = sma(prices: Array(prices.prefix(period)), period: period) ?? 0
        
        for price in prices.dropFirst(period) {
            ema = (price - ema) * multiplier + ema
        }
        
        return ema
    }
    
    // MARK: - RSI (Relative Strength Index)
    
    /// Calculate RSI (14-period default)
    static func rsi(prices: [Double], period: Int = 14) -> Double? {
        guard prices.count > period else { return nil }
        
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }
        
        guard let avgGain = sma(prices: gains, period: period),
              let avgLoss = sma(prices: losses, period: period) else {
            return nil
        }
        
        guard avgLoss != 0 else { return 100 }
        
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }
    
    // MARK: - MACD
    
    struct MACDResult {
        let macd: Double
        let signal: Double
        let histogram: Double
    }
    
    /// Calculate MACD (12, 26, 9 default)
    static func macd(prices: [Double], fastPeriod: Int = 12, slowPeriod: Int = 26, signalPeriod: Int = 9) -> MACDResult? {
        guard let fastEMA = ema(prices: prices, period: fastPeriod),
              let slowEMA = ema(prices: prices, period: slowPeriod) else {
            return nil
        }
        
        let macdLine = fastEMA - slowEMA
        
        // Calculate signal line (EMA of MACD)
        var macdValues: [Double] = []
        for i in slowPeriod..<prices.count {
            let subset = Array(prices.prefix(i + 1))
            if let fast = ema(prices: subset, period: fastPeriod),
               let slow = ema(prices: subset, period: slowPeriod) {
                macdValues.append(fast - slow)
            }
        }
        
        guard let signalLine = ema(prices: macdValues, period: signalPeriod) else {
            return nil
        }
        
        let histogram = macdLine - signalLine
        
        return MACDResult(macd: macdLine, signal: signalLine, histogram: histogram)
    }
    
    // MARK: - Bollinger Bands
    
    struct BollingerBands {
        let upper: Double
        let middle: Double
        let lower: Double
    }
    
    /// Calculate Bollinger Bands (20-period, 2 std dev default)
    static func bollingerBands(prices: [Double], period: Int = 20, stdDevMultiplier: Double = 2.0) -> BollingerBands? {
        guard let middle = sma(prices: prices, period: period) else { return nil }
        
        let recentPrices = Array(prices.suffix(period))
        let variance = recentPrices.map { pow($0 - middle, 2) }.reduce(0, +) / Double(period)
        let stdDev = sqrt(variance)
        
        return BollingerBands(
            upper: middle + (stdDevMultiplier * stdDev),
            middle: middle,
            lower: middle - (stdDevMultiplier * stdDev)
        )
    }
    
    // MARK: - Volume Analysis
    
    /// Calculate average volume
    static func averageVolume(volumes: [Int64], period: Int = 20) -> Double? {
        guard volumes.count >= period else { return nil }
        let recentVolumes = Array(volumes.suffix(period))
        return Double(recentVolumes.reduce(0, +)) / Double(period)
    }
    
    /// Check if volume is above average
    static func isVolumeAboveAverage(currentVolume: Int64, volumes: [Int64], period: Int = 20) -> Bool {
        guard let avgVolume = averageVolume(volumes: volumes, period: period) else { return false }
        return Double(currentVolume) > avgVolume * 1.5
    }
}
