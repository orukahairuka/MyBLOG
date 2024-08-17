import SwiftUI

struct ContentView: View {
    @StateObject private var apiClient = NotionApiClient()
    @State private var searchText = ""
    private let databaseId = "c5a35870-426c-49f0-b766-9991b1c92fa6"  // あなたの実際のデータベースID

    var filteredItems: [Page] {
        if searchText.isEmpty {
            return apiClient.items
        } else {
            return apiClient.items.filter { item in
                item.nameText.lowercased().contains(searchText.lowercased()) ||
                item.tagNames.contains { $0.lowercased().contains(searchText.lowercased()) }
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                if apiClient.isLoading {
                    ProgressView()
                } else if let error = apiClient.error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                } else if apiClient.items.isEmpty {
                    Text("No items found. Check your database ID and API key.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(filteredItems) { item in
                        VStack(alignment: .leading) {
                            Text(item.nameText)
                                .font(.headline)
                            Text("Tags: \(item.tagNames.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Notion Items")
            .searchable(text: $searchText, prompt: "Search by name or tag")
            .onAppear {
                apiClient.fetchDatabaseItems(databaseId: databaseId)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
