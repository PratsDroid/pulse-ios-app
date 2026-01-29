import Foundation

struct PricePoint: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
    
    init(
        id: UUID = UUID(),
        date: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        volume: Int
    ) {
        self.id = id
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

// MARK: - Sample Data
extension PricePoint {
    static func generateSampleData(days: Int = 30, basePrice: Double = 100.0) -> [PricePoint] {
        var points: [PricePoint] = []
        var currentPrice = basePrice
        let calendar = Calendar.current
        
        for i in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            
            // Simulate price movement with some randomness
            let change = Double.random(in: -5...5)
            currentPrice += change
            
            let open = currentPrice
            let high = currentPrice + Double.random(in: 0...3)
            let low = currentPrice - Double.random(in: 0...3)
            let close = Double.random(in: low...high)
            let volume = Int.random(in: 1_000_000...10_000_000)
            
            points.append(PricePoint(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
            
            currentPrice = close
        }
        
        return points
    }
}
