import Foundation
import Alamofire

class NotionApiClient: ObservableObject {
    @Published var items: [Page] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let baseURL = "https://api.notion.com/v1"
    private let apiKey = "secret_5izAgKnmuRtYqCtZ79J3PobSlleh7WGoFdOKuFdOBge"

    func fetchDatabaseItems(databaseId: String) {
        isLoading = true
        error = nil

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Notion-Version": "2022-06-28"
        ]

        AF.request("\(baseURL)/databases/\(databaseId)/query",
                   method: .post,
                   headers: headers)
            .responseDecodable(of: NotionResponse.self) { [weak self] response in
                DispatchQueue.main.async {
                    self?.isLoading = false

                    switch response.result {
                    case .success(let notionResponse):
                        self?.items = notionResponse.results
                    case .failure(let error):
                        print("Decoding error: \(error)")
                        self?.error = error
                    }
                }
            }
    }
}
