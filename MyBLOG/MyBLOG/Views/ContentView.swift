import SwiftUI
import Combine
import Alamofire

// MARK: - Models





enum PropertyValue {
    case title([TitleElement])
    case richText([RichTextElement])
    // Add other cases as needed
}

struct TitleElement: Codable {
    let plainText: String

    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
    }
}

struct RichTextElement: Codable {
    let plainText: String

    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
    }
}

struct Block: Identifiable, Codable {
    let id: String
    let type: String
    let paragraph: ParagraphBlock?
}

struct ParagraphBlock: Codable {
    let richText: [RichTextElement]

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

struct NotionResponse: Codable {
    let object: String
    let results: [NotionPage]
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case object, results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

struct BlockResponse: Codable {
    let results: [Block]
}

struct NotionPage: Identifiable, Codable {
    let id: String
    let properties: [String: PageProperty]

    var title: String {
        if let titleProperty = properties["名前"],
           let titleContent = titleProperty.title,
           let firstTitle = titleContent.first {
            return firstTitle.plainText
        }
        return "Untitled"
    }

    var tags: [String] {
        if let tagProperty = properties["タグ"],
           let multiSelect = tagProperty.multiSelect {
            return multiSelect.map { $0.name }
        }
        return []
    }
}

struct PageProperty: Codable {
    let id: String?
    let type: String
    let multiSelect: [MultiSelectOption]?
    let title: [TextContent]?
    let richText: [TextContent]?
    // 他のプロパティタイプも必要に応じて追加

    enum CodingKeys: String, CodingKey {
        case id, type
        case multiSelect = "multi_select"
        case title
        case richText = "rich_text"
    }
}

struct MultiSelectOption: Codable {
    let id: String
    let name: String
    let color: String
}

struct TextContent: Codable {
    let plainText: String
    let href: String?

    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
        case href
    }
}
// MARK: - NotionApiClient

class NotionApiClient {
    private let baseURL = "https://api.notion.com/v1"
    private let headers: HTTPHeaders
    private let session: Session

    init(apiKey: String) {
        self.headers = [
            "Authorization": "Bearer \(apiKey)",
            "Notion-Version": "2022-06-28",
            "Content-Type": "application/json"
        ]

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.connectionProxyDictionary = [:] // プロキシ設定をバイパス
        self.session = Session(configuration: configuration)
    }

    func queryDatabase(databaseId: String) -> AnyPublisher<[NotionPage], Error> {
        let encodedDatabaseId = databaseId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? databaseId
        let url = "\(baseURL)/databases/\(encodedDatabaseId)/query"

        return session.request(url, method: .post, headers: headers)
            .validate()
            .publishDecodable(type: NotionResponse.self)
            .tryMap { response -> [NotionPage] in
                if let data = response.data {
                    print("Raw API Response:")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print(jsonString)
                    }
                }

                switch response.result {
                case .success(let notionResponse):
                    return notionResponse.results
                case .failure(let error):
                    throw error
                }
            }
            .mapError { error in
                print("Error in queryDatabase: \(error)")
                if let decodingError = error as? DecodingError {
                    print("Decoding error details: \(decodingError)")
                }
                return error
            }
            .eraseToAnyPublisher()
    }

    func getPageBlocks(pageId: String) -> AnyPublisher<[Block], Error> {
        let encodedPageId = pageId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pageId
        let url = "\(baseURL)/blocks/\(encodedPageId)/children"

        return session.request(url, method: .get, headers: headers)
            .validate()
            .publishDecodable(type: BlockResponse.self)
            .tryMap { response -> [Block] in
                switch response.result {
                case .success(let blockResponse):
                    return blockResponse.results
                case .failure(let error):
                    throw error
                }
            }
            .mapError { error in
                print("Error in getPageBlocks: \(error)")
                return error
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - ViewModels

class DatabaseViewModel: ObservableObject {
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
class PageViewModel: ObservableObject {
    @Published var blocks: [Block] = []
    @Published var isLoading = false
    @Published var error: Error?

    let apiClient: NotionApiClient
    var cancellables = Set<AnyCancellable>()

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
                    self?.error = error
                    print("Error in getPageBlocks: \(error)")
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

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search by title or tag", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct PageDetailView: View {
    @StateObject var viewModel: PageViewModel
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
        }
        .onAppear {
            viewModel.fetchBlocks(pageId: pageId)
        }
        .onDisappear {
            // キャンセル処理を追加
            viewModel.cancellables.removeAll()
        }
    }
}

// MARK: - App



@main
struct NotionViewerApp: App {
    let apiClient: NotionApiClient

    init() {
        // APIキーを安全な方法で管理する
#if DEBUG
        let apiKey = "secret_5izAgKnmuRtYqCtZ79J3PobSlleh7WGoFdOKuFdOBge" // 開発時はハードコードされた値を使用
#else
        // 本番環境では、より安全な方法（例：キーチェーン）を使用
        let apiKey = KeychainService.retrieveAPIKey() ?? ""
#endif

        self.apiClient = NotionApiClient(apiKey: apiKey)
    }

    var body: some Scene {
        WindowGroup {
            DatabaseListView(viewModel: DatabaseViewModel(apiClient: apiClient), databaseId: "c5a35870426c49f0b7669991b1c92fa6")
        }
    }
}
