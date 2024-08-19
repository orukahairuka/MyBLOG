//
//  Utility.swift
//  MyBLOG
//
//  Created by 櫻井絵理香 on 2024/08/19.
//
import SwiftUI
import MarkdownUI
import Highlightr

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

