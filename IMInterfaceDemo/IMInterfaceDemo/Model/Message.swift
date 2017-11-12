import Foundation

struct Message: Codable {
    let id: String
    let conversation_id: String
    let user_id: String
    let type: MessageType
    let content: String
    let card_title: String
    let card_remark: String
    let created_at: Date
    let status: String
}

enum MessageStatus: String, Codable {
    case sending
    case delivered
    case unread
    case read
    case failed
}

enum MessageType: String, Codable {
    case text
    case photo
    case video
    case sticker
    case card_contact
    case card_group
    case card_transfer
}
