import Foundation

struct NFTCollection: Decodable {
    let id: String
    let name: String
    let cover: String
    let nfts: [String]
    let description: String
    let author: String

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case cover
        case nfts
        case description
        case author
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try Self.decodeIdentifier(container, key: .id)
        name = try container.decode(String.self, forKey: .name)
        cover = try container.decode(String.self, forKey: .cover)
        description = try container.decode(String.self, forKey: .description)
        author = try container.decode(String.self, forKey: .author)
        nfts = try Self.decodeIdentifiers(container, key: .nfts)
    }

    private static func decodeIdentifier(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> String {
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        return String(try container.decode(Int.self, forKey: key))
    }

    private static func decodeIdentifiers(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> [String] {
        if let values = try? container.decode([String].self, forKey: key) {
            return values
        }
        return try container.decode([Int].self, forKey: key).map(String.init)
    }
}
