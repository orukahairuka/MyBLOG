import SwiftUI
import Combine
import Alamofire

class ArticleDatabase: ObservableObject {
    @Published var pages: [NotionPage] = []
    @Published var filteredPages: [NotionPage] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""

    let apiClient: NotionApiClient
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: NotionApiClient) {
        self.apiClient = apiClient

        // 検索テキストが変更されたときにフィルタリングを実行
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterPages()
            }
            .store(in: &cancellables)
    }

    func fetchPages(databaseId: String) {
        isLoading = true
        error = nil

        apiClient.queryDatabase(databaseId: databaseId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] pages in
                self?.pages = pages
                self?.filterPages()
            }
            .store(in: &cancellables)
    }

    private func filterPages() {
        if searchText.isEmpty {
            filteredPages = pages
        } else {
            filteredPages = pages.filter { page in
                page.title.localizedCaseInsensitiveContains(searchText) ||
                page.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
}

struct DatabaseListView: View {
    @ObservedObject var viewModel: ArticleDatabase
    let databaseId: String

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $viewModel.searchText)

                List(viewModel.filteredPages) { page in
                    NavigationLink(destination: PageDetailView(viewModel: PageViewModel(apiClient: viewModel.apiClient), pageId: page.id)) {
                        VStack(alignment: .leading) {
                            Text(page.title)
                                .font(.headline)
                            HStack {
                                ForEach(page.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Notion Database")
            }
            .onAppear {
                viewModel.fetchPages(databaseId: databaseId)
            }
            .overlay(Group {
                if viewModel.isLoading {
                    ProgressView()
                }
            })
        }
    }
}


