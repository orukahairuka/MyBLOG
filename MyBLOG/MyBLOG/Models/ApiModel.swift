//import Foundation
//
//struct NotionPage: Identifiable, Codable {
//    let id: String
//    let properties: [String: PageProperty]
//}
//
//struct PageProperty: Codable {
//    let type: String
//    let id: String?
//    let value: PropertyValue
//
//    enum CodingKeys: String, CodingKey {
//        case type, id
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        type = try container.decode(String.self, forKey: .type)
//        id = try container.decodeIfPresent(String.self, forKey: .id)
//
//        switch type {
//        case "title":
//            value = .title(try container.decode([TitleElement].self, forKey: .init(stringValue: type)!))
//        case "rich_text":
//            value = .richText(try container.decode([RichTextElement].self, forKey: .init(stringValue: type)!))
//        case "number":
//            value = .number(try container.decode(Double.self, forKey: .init(stringValue: type)!))
//        case "select":
//            value = .select(try container.decode(SelectOption.self, forKey: .init(stringValue: type)!))
//        case "multi_select":
//            value = .multiSelect(try container.decode([SelectOption].self, forKey: .init(stringValue: type)!))
//        case "date":
//            value = .date(try container.decode(DateValue.self, forKey: .init(stringValue: type)!))
//        case "people":
//            value = .people(try container.decode([User].self, forKey: .init(stringValue: type)!))
//        case "files":
//            value = .files(try container.decode([FileObject].self, forKey: .init(stringValue: type)!))
//        case "checkbox":
//            value = .checkbox(try container.decode(Bool.self, forKey: .init(stringValue: type)!))
//        case "url":
//            value = .url(try container.decode(String.self, forKey: .init(stringValue: type)!))
//        case "email":
//            value = .email(try container.decode(String.self, forKey: .init(stringValue: type)!))
//        case "phone_number":
//            value = .phoneNumber(try container.decode(String.self, forKey: .init(stringValue: type)!))
//        case "formula":
//            value = .formula(try container.decode(FormulaResult.self, forKey: .init(stringValue: type)!))
//        case "relation":
//            value = .relation(try container.decode([RelationItem].self, forKey: .init(stringValue: type)!))
//        case "rollup":
//            value = .rollup(try container.decode(RollupResult.self, forKey: .init(stringValue: type)!))
//        case "created_time":
//            value = .createdTime(try container.decode(String.self, forKey: .init(stringValue: type)!))
//        case "created_by":
//            value = .createdBy(try container.decode(User.self, forKey: .init(stringValue: type)!))
//        case "last_edited_time":
//            value = .lastEditedTime(try container.decode(String.self, forKey: .init(stringValue: type)!))
//        case "last_edited_by":
//            value = .lastEditedBy(try container.decode(User.self, forKey: .init(stringValue: type)!))
//        default:
//            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown property type: \(type)")
//        }
//    }
//}
//
//enum PropertyValue {
//    case title([TitleElement])
//    case richText([RichTextElement])
//    case number(Double)
//    case select(SelectOption)
//    case multiSelect([SelectOption])
//    case date(DateValue)
//    case people([User])
//    case files([FileObject])
//    case checkbox(Bool)
//    case url(String)
//    case email(String)
//    case phoneNumber(String)
//    case formula(FormulaResult)
//    case relation([RelationItem])
//    case rollup(RollupResult)
//    case createdTime(String)
//    case createdBy(User)
//    case lastEditedTime(String)
//    case lastEditedBy(User)
//}
//
//struct TitleElement: Codable {
//    let type: String
//    let text: TextContent
//    let annotations: Annotations
//    let plainText: String
//    let href: String?
//
//    enum CodingKeys: String, CodingKey {
//        case type, text, annotations
//        case plainText = "plain_text"
//        case href
//    }
//}
//
//struct RichTextElement: Codable {
//    let type: String
//    let text: TextContent
//    let annotations: Annotations
//    let plainText: String
//    let href: String?
//
//    enum CodingKeys: String, CodingKey {
//        case type, text, annotations
//        case plainText = "plain_text"
//        case href
//    }
//}
//
//struct TextContent: Codable {
//    let content: String
//    let link: Link?
//}
//
//struct Link: Codable {
//    let url: String
//}
//
//struct Annotations: Codable {
//    let bold: Bool
//    let italic: Bool
//    let strikethrough: Bool
//    let underline: Bool
//    let code: Bool
//    let color: String
//}
//
//struct SelectOption: Codable {
//    let id: String
//    let name: String
//    let color: String
//}
//
//struct DateValue: Codable {
//    let start: String
//    let end: String?
//}
//
//struct User: Codable {
//    let id: String
//    let name: String?
//    let avatarUrl: String?
//
//    enum CodingKeys: String, CodingKey {
//        case id, name
//        case avatarUrl = "avatar_url"
//    }
//}
//
//struct FileObject: Codable {
//    let name: String
//    let url: String?
//}
//
//struct FormulaResult: Codable {
//    let type: String
//    let number: Double?
//    let string: String?
//    let boolean: Bool?
//    let date: DateValue?
//}
//
//struct RelationItem: Codable {
//    let id: String
//}
//
//struct RollupResult: Codable {
//    let type: String
//    let number: Double?
//    let date: DateValue?
//    let array: [PageProperty]?
//}
//
//struct Block: Identifiable, Codable {
//    let id: String
//    let type: String
//    let paragraph: ParagraphBlock?
//    // 他のブロックタイプも必要に応じて追加
//}
//
//struct ParagraphBlock: Codable {
//    let richText: [RichTextElement]
//
//    enum CodingKeys: String, CodingKey {
//        case richText = "rich_text"
//    }
//}
//
//// API レスポンス用の構造体
//struct NotionResponse: Codable {
//    let results: [NotionPage]
//}
//
//struct BlockResponse: Codable {
//    let results: [Block]
//}
