import Foundation

enum BeerType: String, Codable {
    case tall
    case normal
}

struct BeerEntry: Codable {
    let id: UUID
    let date: Date
    let type: BeerType
    let amount: Int

    init(id: UUID = UUID(), date: Date, type: BeerType, amount: Int) {
        self.id = id
        self.date = date
        self.type = type
        self.amount = amount
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case type
        case amount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        type = try container.decode(BeerType.self, forKey: .type)
        amount = try container.decode(Int.self, forKey: .amount)
    }
}

struct TrackerData: Codable {
    var startDate: Date
    var entries: [BeerEntry]
}
