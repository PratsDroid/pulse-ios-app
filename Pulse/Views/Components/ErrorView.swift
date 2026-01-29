import SwiftUI

struct ErrorView: View {
    let error: APIError
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Oops!")
                    .font(.title2.bold())
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
            
            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    ErrorView(error: .networkError(URLError(.notConnectedToInternet))) {
        print("Retry tapped")
    }
}
