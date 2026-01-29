import SwiftUI

struct DebugSwiftDataView: View {
    @State private var savedTickers: [String] = []
    @State private var loadedTickers: [String] = []
    @State private var message = ""
    
    private let dataManager = DataManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section("Test Save") {
                    Button("Save Dummy Tickers") {
                        testSave()
                    }
                    
                    if !savedTickers.isEmpty {
                        Text("Saved: \(savedTickers.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Section("Test Load") {
                    Button("Load Tickers") {
                        testLoad()
                    }
                    
                    if !loadedTickers.isEmpty {
                        Text("Loaded: \(loadedTickers.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Text("No tickers loaded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Clear") {
                    Button("Clear All Data", role: .destructive) {
                        clearData()
                    }
                }
                
                Section("Status") {
                    Text(message)
                        .font(.caption)
                }
            }
            .navigationTitle("SwiftData Debug")
        }
    }
    
    private func testSave() {
        let dummyTickers = ["TEST1", "TEST2", "TEST3", "DUMMY", "DEBUG"]
        savedTickers = dummyTickers
        
        do {
            try dataManager.saveWatchlistTickers(dummyTickers)
            message = "✅ Save successful! Check console logs."
        } catch {
            message = "❌ Save failed: \(error.localizedDescription)"
        }
    }
    
    private func testLoad() {
        loadedTickers = dataManager.loadWatchlistTickers()
        
        if loadedTickers.isEmpty {
            message = "⚠️ No tickers found. Try saving first."
        } else {
            message = "✅ Loaded \(loadedTickers.count) tickers"
        }
    }
    
    private func clearData() {
        do {
            try dataManager.saveWatchlistTickers([])
            loadedTickers = []
            savedTickers = []
            message = "🗑️ All data cleared"
        } catch {
            message = "❌ Clear failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    DebugSwiftDataView()
}
