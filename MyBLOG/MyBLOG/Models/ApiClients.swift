//import Foundation
//import Alamofire
//import Combine
//
//class NotionApiClient {
//    private let baseURL = "https://api.notion.com/v1"
//    private let apiKey: String
//    private let headers: HTTPHeaders
//
//    init(apiKey: String) {
//        self.apiKey = apiKey
//        self.headers = [
//            "Accept": "application/json",
//            "Notion-Version": "2022-06-28",
//            "Authorization": "Bearer \(apiKey)"
//        ]
//    }
//
//    // データベースのクエリ
//    func queryDatabase(databaseId: String) -> AnyPublisher<Data, AFError> {
//        let url = "\(baseURL)/databases/\(databaseId)/query"
//        return AF.request(url, method: .post, headers: headers)
//            .validate()
//            .publishData()
//            .value()
//    }
//
//    // ページ情報の取得
//    func getPageInfo(pageId: String) -> AnyPublisher<Data, AFError> {
//        let url = "\(baseURL)/pages/\(pageId)"
//        return AF.request(url, method: .get, headers: headers)
//            .validate()
//            .publishData()
//            .value()
//    }
//
//    // ページのブロック情報の取得
//    func getPageBlocks(pageId: String) -> AnyPublisher<Data, AFError> {
//        let url = "\(baseURL)/blocks/\(pageId)/children"
//        return AF.request(url, method: .get, headers: headers)
//            .validate()
//            .publishData()
//            .value()
//    }
//}
//
//// 使用例
//class NotionManager {
//    private let apiClient: NotionApiClient
//    private var cancellables = Set<AnyCancellable>()
//
//    init(apiKey: String) {
//        self.apiClient = NotionApiClient(apiKey: apiKey)
//    }
//
//    func fetchDatabaseInfo(databaseId: String) {
//        apiClient.queryDatabase(databaseId: databaseId)
//            .sink(receiveCompletion: { completion in
//                switch completion {
//                case .finished:
//                    break
//                case .failure(let error):
//                    print("Error: \(error.localizedDescription)")
//                }
//            }, receiveValue: { data in
//                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                    print("Database Info:")
//                    print(json)
//                }
//            })
//            .store(in: &cancellables)
//    }
//
//    func fetchPageInfo(pageId: String) {
//        apiClient.getPageInfo(pageId: pageId)
//            .zip(apiClient.getPageBlocks(pageId: pageId))
//            .sink(receiveCompletion: { completion in
//                switch completion {
//                case .finished:
//                    break
//                case .failure(let error):
//                    print("Error: \(error.localizedDescription)")
//                }
//            }, receiveValue: { (pageData, blockData) in
//                if let pageJson = try? JSONSerialization.jsonObject(with: pageData, options: []) as? [String: Any],
//                   let blockJson = try? JSONSerialization.jsonObject(with: blockData, options: []) as? [String: Any] {
//                    print("Page Info:")
//                    print(pageJson)
//                    print("==================================================")
//                    print("Block Info:")
//                    print(blockJson)
//                }
//            })
//            .store(in: &cancellables)
//    }
//}
//
//
