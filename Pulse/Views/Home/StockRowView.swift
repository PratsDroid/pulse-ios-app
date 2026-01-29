import SwiftUI

struct StockRowView: View {
    let stock: Stock
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: Ticker and Company Name
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.ticker)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(stock.companyName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Middle: Mini Chart
            SparklineChart(
                data: PricePoint.generateSampleData(days: 7, basePrice: stock.currentPrice),
                isPositive: stock.isPositive
            )
            .frame(width: 80)
            
            // Right: Price and Change
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.currentPrice.asCurrency)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: stock.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2.weight(.semibold))
                    
                    Text(stock.dailyChangePercent.asPercentage)
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(Color.forChange(stock.dailyChange))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(Stock.samples) { stock in
            StockRowView(stock: stock)
        }
    }
    .padding()
    .background(Color.appBackground)
}
