import SwiftUI
import Combine
import Alamofire

// MARK: - Models



// MARK: - NotionApiClient

class NotionApiClient {
    private let baseURL = "https://api.notion.com/v1"
    private let apiKey: String
    private let headers: HTTPHeaders
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.headers = [
            "Accept": "application/json",
            "Notion-Version": "2022-06-28",
            "Authorization": "Bearer \(apiKey)"
        ]
    }
    
    func queryDatabase(databaseId: String) -> AnyPublisher<[NotionPage], Error> {
        let url = "\(baseURL)/databases/\(databaseId)/query"
        return AF.request(url, method: .post, headers: headers)
            .validate()
            .publishDecodable(type: NotionResponse.self)
            .value()
            .map { $0.results }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    func getPageBlocks(pageId: String) -> AnyPublisher<[Block], Error> {
        let url = "\(baseURL)/blocks/\(pageId)/children"
        return AF.request(url, method: .get, headers: headers)
            .validate()
            .publishDecodable(type: BlockResponse.self)
            .value()
            .map { $0.results }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

// MARK: - ViewModels

class DatabaseViewModel: ObservableObject {
    @Published var pages: [NotionPage] = []
    @Published var isLoading = false
    @Published var error: IdentifiableError?
    
    let apiClient: NotionApiClient  // privateを削除
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: NotionApiClient) {
        self.apiClient = apiClient
    }
    
    func fetchPages(databaseId: String) {
        isLoading = true
        error = nil
        
        apiClient.queryDatabase(databaseId: databaseId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = IdentifiableError(error: error)
                }
            } receiveValue: { [weak self] pages in
                self?.pages = pages
            }
            .store(in: &cancellables)
    }
}

class PageViewModel: ObservableObject {
    @Published var blocks: [Block] = []
    @Published var isLoading = false
    @Published var error: IdentifiableError?
    
    let apiClient: NotionApiClient  // privateを削除
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: NotionApiClient) {
        self.apiClient = apiClient
    }
    
    func fetchBlocks(pageId: String) {
        isLoading = true
        error = nil
        
        apiClient.getPageBlocks(pageId: pageId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = IdentifiableError(error: error)
                }
            } receiveValue: { [weak self] blocks in
                self?.blocks = blocks
            }
            .store(in: &cancellables)
    }
}

// MARK: - IdentifiableError

struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: Error
}

// MARK: - Views

struct DatabaseListView: View {
    @ObservedObject var viewModel: DatabaseViewModel
    let databaseId: String
    
    var body: some View {
        NavigationView {
            List(viewModel.pages) { page in
                NavigationLink(destination: PageDetailView(viewModel: PageViewModel(apiClient: viewModel.apiClient), pageId: page.id)) {
                    Text(page.properties["Name"]?.title?.first?.plainText ?? "Untitled")
                }
            }
            .navigationTitle("Notion Database")
            .onAppear {
                viewModel.fetchPages(databaseId: databaseId)
            }
            .overlay(Group {
                if viewModel.isLoading {
                    ProgressView()
                }
            })
            .alert(item: $viewModel.error) { error in
                Alert(title: Text("Error"), message: Text(error.error.localizedDescription))
            }
        }
    }
}

struct PageDetailView: View {
    @ObservedObject var viewModel: PageViewModel
    let pageId: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.blocks) { block in
                    if let paragraph = block.paragraph {
                        Text(paragraph.richText.map { $0.plainText }.joined())
                    }
                }
                .padding()
            }
            .navigationTitle("Page Detail")
            .onAppear {
                viewModel.fetchBlocks(pageId: pageId)
            }
            .overlay(Group {
                if viewModel.isLoading {
                    ProgressView()
                }
            })
            .alert(item: $viewModel.error) { error in
                Alert(title: Text("Error"), message: Text(error.error.localizedDescription))
            }
        }
    }

    // MARK: - App

    @main
    struct NotionViewerApp: App {
        let apiClient = NotionApiClient(apiKey: "secret_5izAgKnmuRtYqCtZ79J3PobSlleh7WGoFdOKuFdOBge")

        var body: some Scene {
            WindowGroup {
                DatabaseListView(viewModel: DatabaseViewModel(apiClient: apiClient), databaseId: "c5a35870426c49f0b7669991b1c92fa6")
            }
        }
    }
}
