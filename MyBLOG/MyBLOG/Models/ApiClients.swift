import Alamofire
import Combine
import SwiftUI

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
