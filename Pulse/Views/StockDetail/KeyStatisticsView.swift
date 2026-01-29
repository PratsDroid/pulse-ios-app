import SwiftUI

struct KeyStatisticsView: View {
    let stock: Stock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Statistics")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // 52 Week Range with slider
                if let week52Low = stock.week52Low, let week52High = stock.week52High {
                    week52RangeView(low: week52Low, high: week52High, current: stock.currentPrice)
                }
                
                Divider()
                    .background(Color.secondary.opacity(0.3))
                
                // Statistics grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    if let previousClose = stock.previousClose {
                        statItem(label: "Previous Close", value: previousClose.asCurrency)
                    }
                    
                    if let openPrice = stock.openPrice {
                        statItem(label: "Open", value: openPrice.asCurrency)
                    }
                    
                    statItem(label: "Volume", value: Double(stock.volume).asCompactNumber)
                    
                    if let avgVolume = stock.avgVolume {
                        statItem(label: "Avg Volume (3M)", value: Double(avgVolume).asCompactNumber)
                    }
                    
                    if let marketCap = stock.marketCap {
                        statItem(label: "Market Cap", value: marketCap.asCompactNumber)
                    }
                    
                    if let peRatio = stock.peRatio {
                        statItem(label: "P/E Ratio", value: String(format: "%.2f", peRatio))
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func week52RangeView(low: Double, high: Double, current: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("52 Week Range")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Range labels
            HStack {
                Text(low.asCurrency)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(high.asCurrency)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Range slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 4)
                    
                    // Current position indicator
                    let position = min(max((current - low) / (high - low), 0), 1)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .offset(x: geometry.size.width * position - 6)
                }
            }
            .frame(height: 12)
        }
    }
    
    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    KeyStatisticsView(stock: Stock.sample)
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
