//
//  MyBLOGApp.swift
//  MyBLOG
//
//  Created by 櫻井絵理香 on 2024/08/13.
//

import SwiftUI

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
