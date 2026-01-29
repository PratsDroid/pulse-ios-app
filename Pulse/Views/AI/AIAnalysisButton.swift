import SwiftUI

struct AIAnalysisButton: View {
    let title: String
    let icon: String
    let type: AIAnalysisType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(Constants.UI.cornerRadius)
        }
        .buttonStyle(.plain)
    }
}
