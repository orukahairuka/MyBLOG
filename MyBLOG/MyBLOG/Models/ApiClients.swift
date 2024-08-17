//
//  ApiClients.swift
//  MyBLOG
//
//  Created by 櫻井絵理香 on 2024/08/16.
//

import Foundation
import Alamofire

class NotionApiClient: ObservableObject {
    @Published var database: Welcome?
    @Published var isLoading = false
    @Published var error: Error?

    private let baseURL = "https://api.notion.com/v1"
    private let apiKey = "secret_5izAgKnmuRtYqCtZ79J3PobSlleh7WGoFdOKuFdOBge"

    func fetchDatabase(id: String) {
        isLoading = true
        error = nil

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Notion-Version": "2022-06-28"
        ]

        AF.request("\(baseURL)/databases/\(id)", headers: headers)
            .responseDecodable(of: Welcome.self) { [weak self] response in
                DispatchQueue.main.async {
                    self?.isLoading = false

                    switch response.result {
                    case .success(let database):
                        self?.database = database
                    case .failure(let error):
                        self?.error = error
                    }
                }
            }
    }
}
