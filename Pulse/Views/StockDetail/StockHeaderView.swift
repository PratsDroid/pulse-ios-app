import SwiftUI

struct StockHeaderView: View {
    let stock: Stock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Company name and ticker
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.companyName)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(stock.ticker)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Market status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(stock.isMarketOpen ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text(stock.isMarketOpen ? "Market Open" : "Market Closed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Current price
            Text(stock.currentPrice.asCurrency)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // Daily change
            PriceChangeLabel(
                change: stock.dailyChange,
                changePercent: stock.dailyChangePercent
            )
            
            // Post-market change (if available)
            if let postMarketChange = stock.postMarketChange,
               let postMarketChangePercent = stock.postMarketChangePercent {
                HStack(spacing: 4) {
                    Text("After Hours:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    PriceChangeLabel(
                        change: postMarketChange,
                        changePercent: postMarketChangePercent,
                        showIcon: false
                    )
                    .font(.caption)
                }
            }
            
            // Last updated with delay disclaimer
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Delayed 15+ min • Updated \(stock.lastUpdated.asRelativeTime)")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

#Preview {
    VStack(spacing: 16) {
        StockHeaderView(stock: Stock.sample)
        
        StockHeaderView(stock: Stock.samples[1])
    }
    .padding()
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
