import Foundation

struct User: Encodable {

    let id: String
    let full_name: String
    let type: UserType
    let alias_name: String
    let identity_number: String
    let avatar_url: String
    let phone: String
    let country: String
    let is_verified: Bool
    let is_blocked: Bool
    let is_notification_enabled: Bool
    let created_at: Date
    let reputation: Int
    
}

extension User: Decodable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        full_name = try container.decode(String.self, forKey: .full_name)
        type = try container.decode(UserType.self, forKey: .type)
        identity_number = try container.decode(String.self, forKey: .identity_number)
        avatar_url = try container.decode(String.self, forKey: .avatar_url)
        alias_name = container.getString(key: .alias_name)
        phone = container.getString(key: .phone)
        country = container.getString(key: .country)
        is_verified = container.getBool(key: .is_verified)
        is_blocked = container.getBool(key: .is_blocked)
        is_notification_enabled = container.getBool(key: .is_notification_enabled)
        reputation = container.getInt(key: .reputation)
        created_at = container.getDate(key: .created_at)
    }
    
}

enum UserType: String, Codable {
    case me
    case contact
    case friend
    case stranger
    case user
}
