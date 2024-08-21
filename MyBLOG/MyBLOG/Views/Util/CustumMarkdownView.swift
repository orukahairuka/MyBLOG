//
//  CustumMarkdownView.swift
//  MyBLOG
//
//  Created by 櫻井絵理香 on 2024/08/21.
//

import SwiftUI
import MarkdownUI

struct CustomMarkdownView: View {
    let markdown: String

    var body: some View {
        ParsedMarkdownView(parsedContent: parseMarkdown(markdown))
    }

    private func parseMarkdown(_ markdown: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let codeBlockRegex = try! NSRegularExpression(pattern: "```(\\w*)\\n([\\s\\S]*?)```", options: [])
        var lastMatchEnd = markdown.startIndex

        let matches = codeBlockRegex.matches(in: markdown, options: [], range: NSRange(markdown.startIndex..., in: markdown))

        for match in matches {
            let matchRange = Range(match.range, in: markdown)!
            let beforeCodeBlock = String(markdown[lastMatchEnd..<matchRange.lowerBound])
            if !beforeCodeBlock.isEmpty {
                elements.append(.text(beforeCodeBlock))
            }

            if let languageRange = Range(match.range(at: 1), in: markdown),
               let codeRange = Range(match.range(at: 2), in: markdown) {
                let language = String(markdown[languageRange])
                let code = String(markdown[codeRange])
                elements.append(.codeBlock(language: language, code: code))
            }

            lastMatchEnd = matchRange.upperBound
        }

        let remainingText = String(markdown[lastMatchEnd...])
        if !remainingText.isEmpty {
            elements.append(.text(remainingText))
        }

        return elements
    }
}

enum MarkdownElement {
    case text(String)
    case codeBlock(language: String, code: String)
}

struct ParsedMarkdownView: View {
    let parsedContent: [MarkdownElement]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(parsedContent.enumerated()), id: \.offset) { _, element in
                    switch element {
                    case .text(let content):
                        Markdown(content)
                    case .codeBlock(let language, let code):
                        CodeBlockView(language: language, code: code)
                    }
                }
            }
            .padding()
        }
    }
}

struct CodeBlockView: View {
    let language: String
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(language)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(10)
            }
            .background(Color.gray.opacity(0.8))
            .cornerRadius(8)
        }
        .padding(.vertical, 5)
    }
}
