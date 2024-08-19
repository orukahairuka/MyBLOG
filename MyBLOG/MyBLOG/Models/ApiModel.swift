import Alamofire

struct NotionResponse: Codable {
    let object: String
    let results: [NotionPage]
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case object, results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

struct BlockResponse: Codable {
    let results: [Block]
}

// MARK: - Page Structure

struct NotionPage: Identifiable, Codable {
    let id: String
    let properties: [String: PageProperty]

    var title: String {
        if let titleProperty = properties["名前"],
           case .title(let titleElements) = titleProperty.value,
           let firstTitle = titleElements.first {
            return firstTitle.plainText
        }
        return "Untitled"
    }

    var tags: [String] {
        if let tagProperty = properties["タグ"],
           case .multiSelect(let options) = tagProperty.value {
            return options.map { $0.name }
        }
        return []
    }
}

struct CustomCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) {
        stringValue = string
        intValue = nil
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

struct PageProperty: Codable {
    let id: String?
    let type: String
    let value: PropertyValue

    enum CodingKeys: String, CodingKey {
        case id, type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CustomCodingKey.self)

        func decodeValue<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T {
            do {
                return try container.decode(T.self, forKey: CustomCodingKey(key))
            } catch DecodingError.keyNotFound(_, _) {
                throw DecodingError.keyNotFound(
                    CustomCodingKey(key),
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "No value found for key \(key)"
                    )
                )
            } catch {
                throw DecodingError.typeMismatch(
                    T.self,
                    DecodingError.Context(
                        codingPath: container.codingPath + [CustomCodingKey(key)],
                        debugDescription: "Failed to decode \(key) as \(T.self)",
                        underlyingError: error
                    )
                )
            }
        }

        id = try container.decodeIfPresent(String.self, forKey: CustomCodingKey("id"))
        type = try container.decode(String.self, forKey: CustomCodingKey("type"))

        switch type {
        case "title":
            value = .title(try decodeValue([RichTextElement].self, forKey: "title"))
        case "rich_text":
            value = .richText(try decodeValue([RichTextElement].self, forKey: "rich_text"))
        case "multi_select":
            value = .multiSelect(try decodeValue([MultiSelectOption].self, forKey: "multi_select"))
        case "select":
            value = .select(try decodeValue(SelectOption.self, forKey: "select"))
        case "number":
            value = .number(try decodeValue(Double.self, forKey: "number"))
        case "date":
            value = .date(try decodeValue(DateValue.self, forKey: "date"))
        case "checkbox":
            value = .checkbox(try decodeValue(Bool.self, forKey: "checkbox"))
        // Add other cases as needed
        default:
            throw DecodingError.dataCorruptedError(
                forKey: CustomCodingKey("type"),
                in: container,
                debugDescription: "Unsupported property type: \(type)"
            )
        }
    }
}

enum PropertyValue {
    case title([RichTextElement])
    case richText([RichTextElement])
    case multiSelect([MultiSelectOption])
    case select(SelectOption)
    case number(Double)
    case date(DateValue)
    case checkbox(Bool)
    // Add other cases as needed
}

struct SelectOption: Codable {
    let id: String
    let name: String
    let color: String
}

struct DateValue: Codable {
    let start: String
    let end: String?
    let timeZone: String?

    enum CodingKeys: String, CodingKey {
        case start, end
        case timeZone = "time_zone"
    }
}



struct MultiSelectOption: Codable {
    let id: String
    let name: String
    let color: String
}

// MARK: - Block Structure

struct Block: Identifiable, Codable {
    let id: String
    let type: String
    let paragraph: ParagraphBlock?
    let heading_1: HeadingBlock?
    let heading_2: HeadingBlock?
    let heading_3: HeadingBlock?
    let bulleted_list_item: ListItemBlock?
    let numbered_list_item: ListItemBlock?
    // Add other block types as needed

    enum CodingKeys: String, CodingKey {
        case id, type, paragraph
        case heading_1, heading_2, heading_3
        case bulleted_list_item, numbered_list_item
    }
}

struct ParagraphBlock: Codable {
    let richText: [RichTextElement]

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

struct HeadingBlock: Codable {
    let richText: [RichTextElement]

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

struct ListItemBlock: Codable {
    let richText: [RichTextElement]

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

// MARK: - Rich Text Elements

struct RichTextElement: Codable {
    let type: String
    let text: TextContent?
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

// MARK: - IdentifiableError

struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: Error
}
