import SwiftUI
import Combine
import Alamofire
import MarkdownUI
import Highlightr

// MARK: - Models


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

// MARK: - Page Structure

struct NotionPage: Identifiable, Codable {
    let id: String
    let properties: [String: PageProperty]

    var title: String {
        if let titleProperty = properties["名前"],
           case .title(let titleElements) = titleProperty.value,
           let firstTitle = titleElements.first {
            return firstTitle.plainText
        }
        return "Untitled"
    }

    var tags: [String] {
        if let tagProperty = properties["タグ"],
           case .multiSelect(let options) = tagProperty.value {
            return options.map { $0.name }
        }
        return []
    }
}

struct CustomCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) {
        stringValue = string
        intValue = nil
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

struct PageProperty: Codable {
    let id: String?
    let type: String
    let value: PropertyValue

    enum CodingKeys: String, CodingKey {
        case id, type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CustomCodingKey.self)

        func decodeValue<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T {
            do {
                return try container.decode(T.self, forKey: CustomCodingKey(key))
            } catch DecodingError.keyNotFound(_, _) {
                throw DecodingError.keyNotFound(
                    CustomCodingKey(key),
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "No value found for key \(key)"
                    )
                )
            } catch {
                throw DecodingError.typeMismatch(
                    T.self,
                    DecodingError.Context(
                        codingPath: container.codingPath + [CustomCodingKey(key)],
                        debugDescription: "Failed to decode \(key) as \(T.self)",
                        underlyingError: error
                    )
                )
            }
        }

        id = try container.decodeIfPresent(String.self, forKey: CustomCodingKey("id"))
        type = try container.decode(String.self, forKey: CustomCodingKey("type"))

        switch type {
        case "title":
            value = .title(try decodeValue([RichTextElement].self, forKey: "title"))
        case "rich_text":
            value = .richText(try decodeValue([RichTextElement].self, forKey: "rich_text"))
        case "multi_select":
            value = .multiSelect(try decodeValue([MultiSelectOption].self, forKey: "multi_select"))
        case "select":
            value = .select(try decodeValue(SelectOption.self, forKey: "select"))
        case "number":
            value = .number(try decodeValue(Double.self, forKey: "number"))
        case "date":
            value = .date(try decodeValue(DateValue.self, forKey: "date"))
        case "checkbox":
            value = .checkbox(try decodeValue(Bool.self, forKey: "checkbox"))
        // Add other cases as needed
        default:
            throw DecodingError.dataCorruptedError(
                forKey: CustomCodingKey("type"),
                in: container,
                debugDescription: "Unsupported property type: \(type)"
            )
        }
    }
}

enum PropertyValue {
    case title([RichTextElement])
    case richText([RichTextElement])
    case multiSelect([MultiSelectOption])
    case select(SelectOption)
    case number(Double)
    case date(DateValue)
    case checkbox(Bool)
    // Add other cases as needed
}

struct SelectOption: Codable {
    let id: String
    let name: String
    let color: String
}

struct DateValue: Codable {
    let start: String
    let end: String?
    let timeZone: String?

    enum CodingKeys: String, CodingKey {
        case start, end
        case timeZone = "time_zone"
    }
}



struct MultiSelectOption: Codable {
    let id: String
    let name: String
    let color: String
}

// MARK: - Block Structure

struct Block: Identifiable, Codable {
    let id: String
    let type: String
    let paragraph: ParagraphBlock?
    let heading_1: HeadingBlock?
    let heading_2: HeadingBlock?
    let heading_3: HeadingBlock?
    let bulleted_list_item: ListItemBlock?
    let numbered_list_item: ListItemBlock?
    // Add other block types as needed

    enum CodingKeys: String, CodingKey {
        case id, type, paragraph
        case heading_1, heading_2, heading_3
        case bulleted_list_item, numbered_list_item
    }
}

struct ParagraphBlock: Codable {
    let richText: [RichTextElement]

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

struct HeadingBlock: Codable {
    let richText: [RichTextElement]

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

struct ListItemBlock: Codable {
    let richText: [RichTextElement]

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

// MARK: - Rich Text Elements

struct RichTextElement: Codable {
    let type: String
    let text: TextContent?
    let annotations: Annotations
    let plainText: String
    let href: String?

    enum CodingKeys: String, CodingKey {
        case type, text, annotations
        case plainText = "plain_text"
        case href
    }
}

struct TextContent: Codable {
    let content: String
    let link: Link?
}

struct Link: Codable {
    let url: String
}

struct Annotations: Codable {
    let bold: Bool
    let italic: Bool
    let strikethrough: Bool
    let underline: Bool
    let code: Bool
    let color: String
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

class RichTextToMarkdownConverter {
    static func convert(blocks: [Block]) -> String {
        var markdown = ""
        for block in blocks {
            switch block.type {
            case "paragraph":
                if let paragraph = block.paragraph {
                    markdown += convertRichTextToMarkdown(richText: paragraph.richText)
                    markdown += "\n\n"
                }
            case "heading_1":
                if let heading = block.heading_1 {
                    markdown += "# " + convertRichTextToMarkdown(richText: heading.richText) + "\n\n"
                }
            case "heading_2":
                if let heading = block.heading_2 {
                    markdown += "## " + convertRichTextToMarkdown(richText: heading.richText) + "\n\n"
                }
            case "heading_3":
                if let heading = block.heading_3 {
                    markdown += "### " + convertRichTextToMarkdown(richText: heading.richText) + "\n\n"
                }
            case "bulleted_list_item":
                if let listItem = block.bulleted_list_item {
                    markdown += "- " + convertRichTextToMarkdown(richText: listItem.richText) + "\n"
                }
            case "numbered_list_item":
                if let listItem = block.numbered_list_item {
                    markdown += "1. " + convertRichTextToMarkdown(richText: listItem.richText) + "\n"
                }
            // 他のブロックタイプも必要に応じて追加
            default:
                print("Unsupported block type: \(block.type)")
            }
        }
        return markdown
    }

    private static func convertRichTextToMarkdown(richText: [RichTextElement]) -> String {
        var markdown = ""
        for element in richText {
            var text = element.plainText
            if element.annotations.bold {
                text = "**\(text)**"
            }
            if element.annotations.italic {
                text = "*\(text)*"
            }
            if element.annotations.strikethrough {
                text = "~~\(text)~~"
            }
            if element.annotations.code {
                text = "`\(text)`"
            }
            if let href = element.href {
                text = "[\(text)](\(href))"
            }
            markdown += text
        }
        return markdown
    }
}

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
    @Published var markdownContent: String = ""
    @Published var isLoading = false
    @Published var error: Error?

    private let apiClient: NotionApiClient
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: NotionApiClient) {
        self.apiClient = apiClient
    }

    func fetchPage(pageId: String) {
        isLoading = true
        error = nil

        apiClient.getPageBlocks(pageId: pageId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] blocks in
                self?.markdownContent = RichTextToMarkdownConverter.convert(blocks: blocks)
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
    @ObservedObject var viewModel: PageViewModel
    let pageId: String

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
            } else {
                CustomMarkdownView(markdown: viewModel.markdownContent)
                    .padding()
            }
        }
        .navigationTitle("Page Detail")
        .onAppear {
            viewModel.fetchPage(pageId: pageId)
        }
    }
}

struct CustomMarkdownView: View {
    let markdown: String

    var body: some View {
        Markdown(content)
            .markdownTheme(.gitHub)
            .markdownCodeSyntaxHighlighter(HighlightrSyntaxHighlighter(theme: .monokai))
    }

    private var content: String {
        // コードブロックを特別に処理
        let codeBlockRegex = try! NSRegularExpression(pattern: "```([\\s\\S]*?)```", options: [])
        let nsRange = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)

        return codeBlockRegex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: nsRange,
            withTemplate: "<pre><code>$1</code></pre>"
        )
    }
}

struct HighlightrSyntaxHighlighter: CodeSyntaxHighlighter {
    func highlightCode(_ code: String, language: String?) -> Text {
        Text("無理じゃん")
    }
    

    func highlightCode(_ code: String, language: String?) -> AttributedString {
        guard let highlightedCode = highlightr.highlight(code, as: language) else {
            return AttributedString(code)
        }
        return AttributedString(highlightedCode)
    }

    let highlightr: Highlightr

    init(theme: HighlightrsTheme) {
        highlightr = Highlightr()!
        highlightr.setTheme(to: theme.rawValue)
    }


}

enum HighlightrsTheme: String {
    case monokai
    // 他のテーマも必要に応じて追加
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
