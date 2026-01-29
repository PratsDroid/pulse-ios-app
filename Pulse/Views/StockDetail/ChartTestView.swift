import SwiftUI

/// Quick test view to verify Robinhood chart is working
struct ChartTestView: View {
    let sampleData = PricePoint.generateSampleData(days: 5, basePrice: 191.52)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Chart Test")
                .font(.title.bold())
            
            Text("\(sampleData.count) data points")
                .font(.caption)
                .foregroundColor(.secondary)
            
            RobinhoodChartView(
                data: sampleData,
                isPositive: true
            )
            .padding()
            
            Spacer()
        }
        .background(Color.appBackground)
    }
}

#Preview {
    ChartTestView()
        .preferredColorScheme(.dark)
}
