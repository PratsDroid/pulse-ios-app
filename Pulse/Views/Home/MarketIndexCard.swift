import SwiftUI

struct MarketIndexCard: View {
    let stock: Stock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Index name with ticker
            VStack(alignment: .leading, spacing: 2) {
                Text("\(stock.companyName) (\(stock.ticker))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Percentage change with triangle
                HStack(spacing: 4) {
                    Text(stock.dailyChangePercent.asPercentage)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Image(systemName: "triangle.fill")
                        .font(.caption2)
                        .rotationEffect(.degrees(stock.isPositive ? 0 : 180))
                }
                .foregroundColor(stock.isPositive ? .green : .red)
            }
            .padding(.bottom, 8)
            
            Spacer()
            
            // Mini sparkline chart
            SparklineChart(
                data: PricePoint.generateSampleData(days: 7, basePrice: stock.currentPrice),
                isPositive: stock.isPositive
            )
            .frame(height: 50)
        }
        .padding(12)
        .frame(width: 160, height: 130)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        HStack(spacing: 12) {
            ForEach(Stock.samples.prefix(3)) { stock in
                MarketIndexCard(stock: stock)
            }
        }
        .padding()
    }
}
