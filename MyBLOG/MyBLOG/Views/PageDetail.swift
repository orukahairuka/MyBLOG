//
//  PageDetail.swift
//  MyBLOG
//
//  Created by 櫻井絵理香 on 2024/08/19.
//

import SwiftUI
import Combine

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

