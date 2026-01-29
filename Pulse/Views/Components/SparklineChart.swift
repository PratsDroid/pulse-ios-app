import SwiftUI
import Charts

struct SparklineChart: View {
    let data: [PricePoint]
    let isPositive: Bool
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Price", point.close)
                )
                .foregroundStyle(isPositive ? Constants.Colors.positiveGreen : Constants.Colors.negativeRed)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 40)
    }
}

#Preview {
    VStack(spacing: 20) {
        SparklineChart(
            data: PricePoint.generateSampleData(days: 7, basePrice: 100),
            isPositive: true
        )
        .padding()
        
        SparklineChart(
            data: PricePoint.generateSampleData(days: 7, basePrice: 100),
            isPositive: false
        )
        .padding()
    }
    .background(Color.appBackground)
}
