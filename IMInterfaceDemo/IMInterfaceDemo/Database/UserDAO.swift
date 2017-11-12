import FMDB

final class UserDAO: BaseDAO {

    static let tableName = "users"
    static let shared = UserDAO()

    private static let idColumn = "id"
    private static let fullNameColumn = "full_name"
    private static let identityNumberColumn = "identity_number"
    private static let typeColumn = "type"
    private static let avatarUrlColumn = "avatar_url"
    private static let phoneColumn = "phone"
    private static let countryColumn = "country"
    private static let reputationColumn = "reputation"
    private static let aliasNameColumn = "alias_name"
    private static let isVerifiedColumn = "is_verified"
    private static let isBlockedColumn = "is_blocked"
    private static let isNotificationEnabledColumn = "is_notification_enabled"
    private static let createdAtColumn = "created_at"

    static let sqlCreateTable = """
    CREATE TABLE IF NOT EXISTS \(tableName) (
    \(idColumn) TEXT PRIMARY KEY,
    \(fullNameColumn) TEXT,
    \(typeColumn) TEXT,
    \(aliasNameColumn) TEXT,
    \(identityNumberColumn) TEXT,
    \(avatarUrlColumn) TEXT,
    \(phoneColumn) TEXT,
    \(countryColumn) TEXT,
    \(reputationColumn) INTEGER DEFAULT 0,
    \(isVerifiedColumn) INTEGER DEFAULT 0,
    \(isBlockedColumn) INTEGER DEFAULT 0,
    \(isNotificationEnabledColumn) INTEGER DEFAULT 0,
    \(createdAtColumn) INTEGER);
    """
    static let sqlAddUniqueIndex = "CREATE UNIQUE INDEX users_index_id ON \(tableName)(\(idColumn));"
    static let sqlInsert = """
    INSERT INTO \(tableName) (
    \(idColumn),
    \(fullNameColumn),
    \(typeColumn),
    \(aliasNameColumn),
    \(identityNumberColumn),
    \(avatarUrlColumn),
    \(phoneColumn),
    \(countryColumn),
    \(reputationColumn),
    \(isVerifiedColumn),
    \(isBlockedColumn),
    \(isNotificationEnabledColumn),
    \(createdAtColumn)
    ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?);
    """

    private static let sqlQueryContacts = """
    SELECT * FROM \(tableName) WHERE \(typeColumn) = '\(UserType.friend)'
    """

    static let sqlQueryUserByNameOrPhone = """
        SELECT * FROM \(tableName) WHERE \(fullNameColumn) LIKE ? OR \(phoneColumn) LIKE ?
    """

    func count() -> Int {
        var result = 0
        if let rs = executeQuery("SELECT COUNT(*) AS 'count' FROM \(UserDAO.tableName)") {
            if rs.next() {
                result = Int(rs.int(forColumn: "count"))
            }
            database.close()
        }
        return result
    }
    
    func getUsers(nameOrPhone keyword: String) -> [User] {
        guard !keyword.isEmpty else {
            return []
        }
        var result = [User]()
        let replacement = "%\(keyword)%"
        if let rs = executeQuery(UserDAO.sqlQueryUserByNameOrPhone, values: replacement, replacement) {
            while rs.next() {
                result.append(fillResultSet(rs))
            }
            database.close()
        }
        return result
    }

    func contacts() -> [User] {
        var arrays = Array<User>()
        if let rs = executeQuery(UserDAO.sqlQueryContacts) {
            while rs.next() {
                arrays.append(fillResultSet(rs))
            }
            database.close()
        }
        return arrays
    }

    func syncContacts(contacts: [User]) -> Int {
        var changes = 0
        for contact in contacts {
            if executeUpdate(UserDAO.sqlInsert, values: contact.id, contact.full_name, UserType.friend.rawValue, contact.alias_name, contact.identity_number, contact.avatar_url, contact.phone, contact.country, contact.reputation, contact.is_verified, contact.is_blocked, contact.is_notification_enabled, contact.created_at) > 0 {
                changes += 1
            }
        }
        return changes
    }

    private func fillResultSet(_ rs: FMResultSet) -> User {
        let id = rs.string(forColumn: UserDAO.idColumn) ?? ""
        let full_name = rs.string(forColumn: UserDAO.fullNameColumn) ?? ""
        let identity_number = rs.string(forColumn: UserDAO.identityNumberColumn) ?? ""
        let relationship = UserType(rawValue: rs.string(forColumn: UserDAO.typeColumn) ?? "") ?? UserType.stranger
        let alias_name = rs.string(forColumn: UserDAO.aliasNameColumn) ?? ""
        let avatar_url = rs.string(forColumn: UserDAO.avatarUrlColumn) ?? ""
        let phone = rs.string(forColumn: UserDAO.phoneColumn) ?? ""
        let country = rs.string(forColumn: UserDAO.countryColumn) ?? ""
        let is_verified = rs.bool(forColumn: UserDAO.isVerifiedColumn)
        let is_blocked = rs.bool(forColumn: UserDAO.isBlockedColumn)
        let is_notification_enabled = rs.bool(forColumn: UserDAO.isNotificationEnabledColumn)
        let reputation = Int(rs.int(forColumn: UserDAO.reputationColumn))
        let created_at = rs.date(forColumn: UserDAO.createdAtColumn) ?? Date()
        return User(id: id, full_name: full_name, type: relationship, alias_name: alias_name, identity_number: identity_number, avatar_url: avatar_url, phone: phone, country: country, is_verified: is_verified, is_blocked: is_blocked, is_notification_enabled: is_notification_enabled, created_at: created_at, reputation: reputation)
    }
    
}

