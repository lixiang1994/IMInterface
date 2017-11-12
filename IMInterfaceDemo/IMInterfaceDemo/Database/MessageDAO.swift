import FMDB

final class MessageDAO: BaseDAO {

    static let tableName = "messages"
    static let shared = MessageDAO()

    private static let idColumn = "id"
    private static let conversationIdColumn = "conversation_id"
    private static let userIdColumn = "user_id"
    private static let typeColumn = "type"
    private static let contentColumn = "content"
    private static let cardTitleColumn = "card_title"
    private static let cardRemarkColumn = "card_remark"
    private static let createdAtColumn = "created_at"
    private static let mediaUrlColumn = "media_url"
    private static let mediaMineTypeColumn = "media_mine_type"
    private static let mediaSizeColumn = "media_size"
    private static let mediaDurationColumn = "media_duration"
    private static let mediaWidthColumn = "media_width"
    private static let mediaHeightColumn = "media_height"
    private static let mediaHashColumn = "media_hash"
    private static let thumbImageUrlColumn = "thumb_image_url"
    private static let statusColumn = "status"

    static let sqlCreateTable = """
    CREATE TABLE IF NOT EXISTS \(tableName) (
    \(idColumn) TEXT PRIMARY KEY,
    \(conversationIdColumn) TEXT,
    \(userIdColumn) TEXT,
    \(typeColumn) TEXT,
    \(contentColumn) TEXT,
    \(cardTitleColumn) TEXT,
    \(cardRemarkColumn) TEXT,
    \(mediaUrlColumn) TEXT,
    \(mediaMineTypeColumn) TEXT,
    \(mediaSizeColumn) INTEGER,
    \(mediaDurationColumn) INTEGER,
    \(mediaWidthColumn) INTEGER,
    \(mediaHeightColumn) INTEGER,
    \(mediaHashColumn) TEXT,
    \(thumbImageUrlColumn) TEXT,
    \(statusColumn) TEXT,
    \(createdAtColumn) INTEGER);
    """
    static let sqlAddUniqueIndex = "CREATE UNIQUE INDEX messages_index_id ON \(tableName)(\(idColumn));"
    static let sqlTrigger = """
    CREATE TRIGGER conversation_last_message_update AFTER INSERT
    ON messages
    BEGIN
        UPDATE conversations SET last_message_id = new.id where id = new.conversation_id;
    END;
    """
    static let sqlInsert = """
    INSERT INTO \(tableName) (
    \(idColumn),
    \(conversationIdColumn),
    \(userIdColumn),
    \(typeColumn),
    \(contentColumn),
    \(cardTitleColumn),
    \(cardRemarkColumn),
    \(mediaUrlColumn),
    \(mediaMineTypeColumn),
    \(mediaSizeColumn),
    \(mediaDurationColumn),
    \(mediaWidthColumn),
    \(mediaHeightColumn),
    \(mediaHashColumn),
    \(thumbImageUrlColumn),
    \(statusColumn),
    \(createdAtColumn)
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);
    """

    private static let sqlQueryMessagesByConversationId = """
    SELECT m.*, u.full_name as userFullName, u.identity_number as userIdentityNumber FROM messages m LEFT JOIN users u ON m.user_id = u.id where m.conversation_id = ?
    """
    private static let sqlQueryMessagesByContent = """
        SELECT m.id, u.avatar_url, u.full_name, u.identity_number, m.content, m.created_at
        FROM messages m
        LEFT JOIN users u ON m.user_id = u.id
        WHERE m.type = 'text' AND m.content LIKE ?
        ORDER BY m.created_at DESC
    """
    
    func getMessages(conversationId: String) -> [MessageItem] {
        var arrays = Array<MessageItem>()
        if !conversationId.isEmpty {
            if let rs = executeQuery(MessageDAO.sqlQueryMessagesByConversationId, values: conversationId) {
                while rs.next() {
                    arrays.append(fillMessageItem(rs))
                }
                database.close()
            }
        }
        return arrays
    }

    func getMessages(content: String) -> [MessageSearchResult] {
        var result = Array<MessageSearchResult>()
        if !content.isEmpty {
            let replacement = "%\(content)%"
            if let rs = executeQuery(MessageDAO.sqlQueryMessagesByContent, values: replacement) {
                while rs.next() {
                    result.append(MessageSearchResult(resultSet: rs))
                }
                database.close()
            }
        }
        return result
    }

    func sendMessage(message: MessageItem) {
        if executeUpdate(MessageDAO.sqlInsert, values: message.messageId, message.conversationId, message.userId, message.type.rawValue, message.content, message.cardTitle, message.cardRemark, message.mediaUrl, message.mediaMineType, message.mediaSize, message.mediaDuration, message.mediaWidth, message.mediaHeight, message.mediaHash, message.thumbImageUrl, message.status.rawValue, message.createdAt) > 0 {
            NotificationCenter.default.postOnMain(name: NSNotification.Name.MessageDidChange, object: message)
        }
    }

    private func fillMessage(_ rs: FMResultSet) -> Message {
        let id = rs.getString(forColumn: MessageDAO.idColumn)
        let conversation_id = rs.getString(forColumn: MessageDAO.conversationIdColumn)
        let user_id = rs.getString(forColumn: MessageDAO.userIdColumn)
        let type = MessageType(rawValue: rs.getString(forColumn: MessageDAO.typeColumn)) ?? MessageType.text
        let content = rs.getString(forColumn: MessageDAO.contentColumn)
        let card_title = rs.getString(forColumn: MessageDAO.cardTitleColumn)
        let card_remark = rs.getString(forColumn: MessageDAO.cardRemarkColumn)
        let status = rs.getString(forColumn: MessageDAO.statusColumn)
        let created_at = rs.getDate(forColumn: MessageDAO.createdAtColumn)
        return Message(id: id, conversation_id: conversation_id, user_id: user_id, type: type, content: content, card_title: card_title, card_remark: card_remark, created_at: created_at, status: status)
    }

    private func fillMessageItem(_ rs: FMResultSet) -> MessageItem {
        let messageId = rs.getString(forColumn: MessageDAO.idColumn)
        let conversationId =  rs.getString(forColumn: MessageDAO.conversationIdColumn)
        let content = rs.getString(forColumn: MessageDAO.contentColumn)
        let createdAt = rs.getDate(forColumn: MessageDAO.createdAtColumn)

        var message = MessageItem(messageId: messageId, conversationId: conversationId, content: content, createdAt: createdAt)
        message.userId = rs.getString(forColumn: MessageDAO.userIdColumn)
        message.type = MessageType(rawValue: rs.getString(forColumn: MessageDAO.typeColumn)) ?? MessageType.text
        message.cardTitle = rs.getString(forColumn: MessageDAO.cardTitleColumn)
        message.cardRemark = rs.getString(forColumn: MessageDAO.cardRemarkColumn)
        message.mediaUrl = rs.getString(forColumn: MessageDAO.mediaUrlColumn)
        message.mediaMineType = rs.getString(forColumn: MessageDAO.mediaMineTypeColumn)
        message.mediaSize = rs.getInt(forColumn: MessageDAO.mediaSizeColumn)
        message.mediaDuration = rs.getInt(forColumn: MessageDAO.mediaDurationColumn)
        message.mediaWidth = rs.getInt(forColumn: MessageDAO.mediaWidthColumn)
        message.mediaHeight = rs.getInt(forColumn: MessageDAO.mediaHeightColumn)
        message.mediaHash = rs.getString(forColumn: MessageDAO.mediaHashColumn)
        message.thumbImageUrl = rs.getString(forColumn: MessageDAO.thumbImageUrlColumn)
        message.status = MessageStatus(rawValue: rs.getString(forColumn: MessageDAO.statusColumn)) ?? MessageStatus.sending
        message.userFullName = rs.getString(forColumn: "userFullName")
        message.userIdentityNumber = rs.getString(forColumn: "userIdentityNumber")
        return message
    }

}

struct MessageItem {
    let messageId: String
    let conversationId: String
    var type: MessageType
    let createdAt: Date
    var status: MessageStatus
    var userId = ""
    var userFullName  = ""
    var userIdentityNumber = ""
    var content = ""
    var cardTitle = ""
    var cardRemark = ""
    var mediaUrl = ""
    var mediaMineType = ""
    var mediaSize = 0
    var mediaDuration = 0
    var mediaWidth = 0
    var mediaHeight = 0
    var mediaHash = ""
    var thumbImageUrl = ""

    init(messageId: String, conversationId: String, content: String, createdAt: Date = Date()) {
        self.messageId = messageId
        self.conversationId = conversationId
        self.content = content
        self.createdAt = createdAt
        self.status = .sending
        self.type = .text
    }

    init(messageId: String, conversationId: String, mediaUrl: String, createdAt: Date = Date()) {
        self.messageId = messageId
        self.conversationId = conversationId
        self.mediaUrl = mediaUrl
        self.createdAt = createdAt
        self.status = .sending
        self.type = .photo
    }
}

struct MessageSearchResult {
    let id: String
    let userAvatarURL: String
    let userFullname: String
    let userIdentityNumber: String
    let content: String
    let createdAt: Date
    
    init(resultSet rs: FMResultSet) {
        id = rs.string(forColumn: "id") ?? ""
        userAvatarURL = rs.string(forColumn: "avatar_url") ?? ""
        userFullname = rs.string(forColumn: "full_name") ?? ""
        userIdentityNumber = rs.string(forColumn: "identity_number") ?? ""
        content = rs.string(forColumn: "content") ?? ""
        createdAt = rs.date(forColumn: "created_at") ?? Date()
    }
}
