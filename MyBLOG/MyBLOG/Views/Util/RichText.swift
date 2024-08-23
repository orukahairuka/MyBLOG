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
            case "code":
                if let codeBlock = block.code {
                    let language = codeBlock.language
                    let code = convertRichTextToMarkdown(richText: codeBlock.richText)
                    markdown += "```\(language)\n\(code)\n```\n\n"
                }
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

struct HighlightrSyntaxHighlighter: CodeSyntaxHighlighter {
    let highlightr: Highlightr

    init(theme: HighlightrsTheme) {
        highlightr = Highlightr()!
        highlightr.setTheme(to: theme.rawValue)
    }

    func highlightCode(_ code: String, language: String?) -> Text {
        guard let highlightedCode = highlightr.highlight(code, as: language),
              let attributedString = try? AttributedString(highlightedCode, including: \.uiKit) else {
            return Text(code)
        }
        return Text(attributedString)
    }
}

enum HighlightrsTheme: String {
    case monokai
    // 他のテーマも必要に応じて追加
}
