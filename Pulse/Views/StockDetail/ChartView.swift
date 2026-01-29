import SwiftUI
import Charts

struct ChartView: View {
    let data: [PricePoint]
    let isPositive: Bool
    @State private var selectedPoint: PricePoint?
    
    private var minPrice: Double {
        data.map { $0.low }.min() ?? 0
    }
    
    private var maxPrice: Double {
        data.map { $0.high }.max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Selected point info or current price
            if let selected = selectedPoint {
                selectedPointInfo(selected)
            }
            
            // Chart
            Chart {
                ForEach(data) { point in
                    // Area under the line
                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Low", minPrice),
                        yEnd: .value("Price", point.close)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                (isPositive ? Constants.Colors.positiveGreen : Constants.Colors.negativeRed).opacity(0.3),
                                (isPositive ? Constants.Colors.positiveGreen : Constants.Colors.negativeRed).opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Line
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.close)
                    )
                    .foregroundStyle(isPositive ? Constants.Colors.positiveGreen : Constants.Colors.negativeRed)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                    // Selection indicator
                    if let selected = selectedPoint, selected.id == point.id {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Price", point.close)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(100)
                    }
                }
            }
            .chartYScale(domain: minPrice * 0.995...maxPrice * 1.005)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatAxisDate(date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text(price.asCurrency)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(height: 300)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func selectedPointInfo(_ point: PricePoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(point.close.asCurrency)
                .font(.title.bold())
                .foregroundColor(.primary)
            
            Text(point.date.asDateTime)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                infoItem(label: "Open", value: point.open.asCurrency)
                infoItem(label: "High", value: point.high.asCurrency)
                infoItem(label: "Low", value: point.low.asCurrency)
                infoItem(label: "Vol", value: Double(point.volume).asCompactNumber)
            }
            .font(.caption)
        }
    }
    
    private func infoItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundColor(.secondary)
            Text(value)
                .foregroundColor(.primary)
                .fontWeight(.semibold)
        }
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        // Determine format based on data range
        if let first = data.first, let last = data.last {
            let daysDiff = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 0
            
            if daysDiff <= 1 {
                formatter.dateFormat = "HH:mm"
            } else if daysDiff <= 30 {
                formatter.dateFormat = "MMM d"
            } else {
                formatter.dateFormat = "MMM yyyy"
            }
        } else {
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        ChartView(
            data: PricePoint.generateSampleData(days: 30, basePrice: 150),
            isPositive: true
        )
        .padding()
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
