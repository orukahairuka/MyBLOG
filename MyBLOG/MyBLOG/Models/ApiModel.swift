import Foundation

struct NotionResponse: Codable {
    let object: String
    let results: [Page]
    let nextCursor: String?
    let hasMore: Bool
    let type: String
    let pageOrDatabase: [String: String]
    let requestId: String

    enum CodingKeys: String, CodingKey {
        case object, results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
        case type
        case pageOrDatabase = "page_or_database"
        case requestId = "request_id"
    }
}

struct Page: Codable, Identifiable {
    let object: String
    let id: String
    let createdTime: String
    let lastEditedTime: String
    let createdBy, lastEditedBy: User
    let cover: String?
    let icon: String?
    let parent: Parent
    let archived: Bool
    let inTrash: Bool
    let properties: Properties
    let url: String
    let publicUrl: String?

    enum CodingKeys: String, CodingKey {
        case object, id
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case createdBy = "created_by"
        case lastEditedBy = "last_edited_by"
        case cover, icon, parent, archived
        case inTrash = "in_trash"
        case properties, url
        case publicUrl = "public_url"
    }
}

struct User: Codable {
    let object, id: String
}

struct Parent: Codable {
    let type: String
    let databaseId: String

    enum CodingKeys: String, CodingKey {
        case type
        case databaseId = "database_id"
    }
}

struct Properties: Codable {
    let tags: MultiSelect
    let name: Title

    enum CodingKeys: String, CodingKey {
        case tags = "タグ"
        case name = "名前"
    }
}

struct MultiSelect: Codable {
    let id: String
    let type: String
    let multiSelect: [Tag]

    enum CodingKeys: String, CodingKey {
        case id, type
        case multiSelect = "multi_select"
    }
}

struct Tag: Codable {
    let id: String
    let name: String
    let color: String
}

struct Title: Codable {
    let id: String
    let type: String
    let title: [TitleElement]
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

struct TextContent: Codable {
    let content: String
    let link: String?
}

struct Annotations: Codable {
    let bold, italic, strikethrough, underline: Bool
    let code: Bool
    let color: String
}

// Pageモデルの拡張
extension Page {
    var nameText: String {
        return properties.name.title.first?.plainText ?? ""
    }

    var tagNames: [String] {
        return properties.tags.multiSelect.map { $0.name }
    }
}
