
// ApiModel.swift

import Foundation

struct NotionPage: Identifiable, Codable {
    let id: String
    let properties: [String: PageProperty]
}

struct PageProperty: Codable {
    let title: [TitleElement]?
    let richText: [RichTextElement]?
    let number: Int?
    let select: SelectOption?
    // 他のプロパティタイプも必要に応じて追加

    enum CodingKeys: String, CodingKey {
        case title
        case richText = "rich_text"
        case number
        case select
    }
}

struct TitleElement: Codable {
    let type: String
    let text: TextContent
    let annotations: Annotations
    let plainText: String
    let href: String?

    enum CodingKeys: String, CodingKey {
        case type, text, annotations
        case plainText = "plain_text"
        case href
    }
}

struct RichTextElement: Codable {
    let type: String
    let text: TextContent
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

struct SelectOption: Codable {
    let id: String
    let name: String
    let color: String
}

struct Block: Identifiable, Codable {
    let id: String
    let type: String
    let paragraph: ParagraphBlock?
    // 他のブロックタイプも必要に応じて追加
}

struct ParagraphBlock: Codable {
    let richText: [RichTextElement]

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

// API レスポンス用の構造体
struct NotionResponse: Codable {
    let results: [NotionPage]
}

struct BlockResponse: Codable {
    let results: [Block]
}
