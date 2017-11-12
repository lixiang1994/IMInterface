import FMDB

final class ConversationDAO: BaseDAO {

    static let tableName = "conversations"
    static let shared = ConversationDAO()

    private static let idColumn = "id"
    private static let conversationIdColumn = "conversation_id"
    private static let categoryColumn = "category"
    private static let nameColumn = "name"
    private static let iconUrlColumn = "icon_url"
    private static let announcementColumn = "announcement"
    private static let webUrlColumn = "web_url"
    private static let payTypeColumn = "pay_type"
    private static let currencyIdColumn = "currency_id"
    private static let currencyAmountColumn = "currency_amount"
    private static let ownerIdColumn = "owner_id"
    private static let lastMessageIdColumn = "last_message_id"
    private static let lastReadMessageIdColumn = "last_read_message_id"
    private static let unseenMessageCountColumn = "unseen_message_count"
    private static let createdAtColumn = "created_at"

    static let sqlCreateTable = """
    CREATE TABLE IF NOT EXISTS \(tableName) (
    \(idColumn) INTEGER PRIMARY KEY AUTOINCREMENT,
    \(conversationIdColumn) TEXT,
    \(categoryColumn) TEXT,
    \(nameColumn) TEXT,
    \(iconUrlColumn) TEXT,
    \(announcementColumn) TEXT,
    \(webUrlColumn) TEXT,
    \(payTypeColumn) TEXT,
    \(currencyIdColumn) TEXT,
    \(currencyAmountColumn) TEXT,
    \(ownerIdColumn) TEXT,
    \(lastMessageIdColumn) TEXT,
    \(lastReadMessageIdColumn) TEXT,
    \(unseenMessageCountColumn) INTEGER DEFAULT 0,
    \(createdAtColumn) INTEGER);
    """
    static let sqlAddUniqueIndex = "CREATE UNIQUE INDEX conversation_index_id ON \(tableName)(\(conversationIdColumn));"
    static let sqlInsert = """
    INSERT INTO \(tableName) (
    \(conversationIdColumn),
    \(categoryColumn),
    \(nameColumn),
    \(iconUrlColumn),
    \(announcementColumn),
    \(webUrlColumn),
    \(payTypeColumn),
    \(currencyIdColumn),
    \(currencyAmountColumn),
    \(ownerIdColumn),
    \(createdAtColumn)
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?);
    """

    private static let sqlQueryConversationList = """
    SELECT m.conversation_id as id, m.user_id as userId, c.icon_url as iconUrl, c.category as type,
     c.name as name, m.content, m.type as contentType, m.created_at as createdAt, u.identity_number as userIdentityNumber from messages m
     left join conversations c on m.conversation_id = c.conversation_id
     left join users u on u.id = c.owner_id group by m.conversation_id order by m.created_at DESC
    """
    private static let sqlQueryConversationId = "SELECT id FROM \(tableName) WHERE \(ownerIdColumn) = ? and \(categoryColumn) = 'contact'"

    func getConversationIdIfExists(userId: String) -> String? {
        return executeScalar(ConversationDAO.sqlQueryConversationId, values: userId)
    }

    func addContactCoversation(name: String, iconUrl: String, userId: String) -> String {
        let conversationId = UUID().uuidString
        executeUpdate(ConversationDAO.sqlInsert, values: conversationId, "contact", name, iconUrl, "", "", "", "", "", userId, Date())
        return conversationId
    }

    func conversationList() -> [ConversationItem] {
        var arrays = Array<ConversationItem>()
        if let rs = executeQuery(ConversationDAO.sqlQueryConversationList) {
            while rs.next() {
                arrays.append(fillConversationItem(rs))
            }
            database.close()
        }
        return arrays
    }

    private func fillConversationItem(_ rs: FMResultSet) -> ConversationItem {
        let id = rs.string(forColumn: "id") ?? ""
        let userId = rs.string(forColumn: "userId") ?? ""
        let userIdentityNumber = rs.string(forColumn: "userIdentityNumber") ?? ""
        let iconUrl =  rs.string(forColumn: "iconUrl") ?? ""
        let type = rs.string(forColumn: "type") ?? ""
        let name = rs.string(forColumn: "name") ?? ""
        let content = rs.string(forColumn: "content") ?? ""
        let contentType = rs.string(forColumn: "contentType") ?? ""
        let created_at = rs.date(forColumn: "createdAt") ?? Date()
        return ConversationItem(id: id, userId: userId, userIdentityNumber: userIdentityNumber, iconUrl: iconUrl, type: type, name: name, content: content, contentType: contentType, created_at: created_at)
    }

}

struct ConversationItem {
    let id: String
    let userId: String
    let userIdentityNumber: String
    let iconUrl: String
    let type: String
    let name: String
    let content: String
    let contentType: String
    let created_at: Date
}
