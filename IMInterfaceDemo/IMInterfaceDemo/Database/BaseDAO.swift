import FMDB

class BaseDAO {

    private let secretKey = "x'2DD29CA851E7B56E4697B0E1F08507293D761A05CE4D1B628663F411A8086D99"
    private let databaseName = "im.db"
    private let databaseVersion: UInt32 = 5
    internal var database: FMDatabase

    init() {
        let path = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(databaseName).path
        database = FMDatabase(path: path)
        database.logsErrors = false
        if checkDbVersion() {
            onDbUpgrade()
            updateDbVersion()
        }
    }

    @discardableResult
    func batchUpdate(_ exec: (_ database: FMDatabase) -> Int) -> Int {
        if !database.open() {
            return -1
        }
        database.setKey(secretKey)

        defer {
            database.close()
        }

        return exec(database)
    }

    @discardableResult
    func executeUpdate(_ sql: String, values: Any...) -> Int {
        if !database.open() {
            return -1
        }
        database.setKey(secretKey)

        defer {
            database.close()
        }

        do {
            try database.executeUpdate(sql, values: values)
            return Int(database.changes)
        } catch let error as NSError {
            #if DEBUG
                print("failed: \(error.localizedDescription)")
            #endif
        }
        return -1
    }

    @discardableResult
    func executeQuery(_ sql: String, values: Any...) -> FMResultSet? {
        if !database.open() {
            return nil
        }
        database.setKey(secretKey)

        do {
            let rs = try database.executeQuery(sql, values: values)
            return rs
        } catch let error as NSError {
            #if DEBUG
                print("failed: \(error.localizedDescription)")
            #endif
        }
        return nil
    }

    func executeScalar(_ sql: String, values: Any...) -> String? {
        if let rs = executeQuery(sql, values: values) {
            defer {
                database.close()
            }

            if rs.next() {
                return rs.string(forColumnIndex: 0)
            }
        }
        return nil
    }

    private func onDbUpgrade() {
        batchUpdate { (db) -> Int in
            do {
                try db.executeUpdate("DROP TABLE IF EXISTS \(UserDAO.tableName)", values: [])
                try db.executeUpdate(UserDAO.sqlCreateTable, values: [])
                try db.executeUpdate(UserDAO.sqlAddUniqueIndex, values: [])

                try db.executeUpdate("DROP TABLE IF EXISTS \(ConversationDAO.tableName)", values: [])
                try db.executeUpdate(ConversationDAO.sqlCreateTable, values: [])
                try db.executeUpdate(ConversationDAO.sqlAddUniqueIndex, values: [])

                try db.executeUpdate("DROP TABLE IF EXISTS \(MessageDAO.tableName)", values: [])
                try db.executeUpdate(MessageDAO.sqlCreateTable, values: [])
                try db.executeUpdate(MessageDAO.sqlTrigger, values: [])
                try db.executeUpdate(MessageDAO.sqlAddUniqueIndex, values: [])

                try insertTestData(db: db)
                return 1
            } catch let error as NSError {
                print("======BaseDAO......failed: \(error)")
                return 0
            }
        }
    }

    private func checkDbVersion() -> Bool {
        if !database.open() {
            return false
        }
        database.setKey(secretKey)

        defer {
            database.close()
        }
        return databaseVersion != database.userVersion
    }

    private func updateDbVersion() {
        if !database.open() {
            return
        }
        database.setKey(secretKey)

        defer {
            database.close()
        }
        database.userVersion = databaseVersion
    }

    private func insertTestData(db: FMDatabase) throws  {
        // === conversation table test data
        try db.executeUpdate(ConversationDAO.sqlInsert, values: ["5412b65a6c69322082020000", "contact", "Tom", "http://demo-resources.oss-cn-beijing.aliyuncs.com/iminterfacedemo/head1.jpg", "", "", "", "", "", "", Date()])
        try db.executeUpdate(ConversationDAO.sqlInsert, values: ["539abf3e307861502f150001", "contact", "Jack", "http://demo-resources.oss-cn-beijing.aliyuncs.com/iminterfacedemo/head2.jpg", "", "", "", "", "", "", Date()])


        // === users table test data
        try db.executeUpdate(UserDAO.sqlInsert, values: ["5412b65a6c69322082020000", "LEE", "me", "", "1994", "http://demo-resources.oss-cn-beijing.aliyuncs.com/iminterfacedemo/head_png.png", "18611401994", "+86", 100, 0, 0, 1, Date()])
        try db.executeUpdate(UserDAO.sqlInsert, values: ["539abf3e307861502f150000", "Tom", "contact", "", "10002", "http://demo-resources.oss-cn-beijing.aliyuncs.com/iminterfacedemo/head1.jpg", "18611111995", "+86", 120, 0, 0, 1, Date()])
        try db.executeUpdate(UserDAO.sqlInsert, values: ["5392a05e30786145d60b0000", "Jack", "friend", "", "10001", "http://demo-resources.oss-cn-beijing.aliyuncs.com/iminterfacedemo/head2.jpg", "18611111996", "+86", 150, 0, 0, 1, Date()])

        // === messages table test data
        try db.executeUpdate(MessageDAO.sqlInsert, values: ["539abf3e307861502f150000", "5412b65a6c69322082020000", "539abf3e307861502f150000", "text", "Hello Lee, nice to meet you", "", "", "", "", 0, 0, 0, 0, "", "", "read", Date()])
        try db.executeUpdate(MessageDAO.sqlInsert, values: ["539abf3e307861502f150001", "5412b65a6c69322082020000", "539abf3e307861502f150000", "photo", "", "", "", "http://demo-resources.oss-cn-beijing.aliyuncs.com/newsdetailsdemo/6eee549a554b1d66409.jpg", "jpg", 0, 0, 455, 342, "", "", "read", Date()])
        try db.executeUpdate(MessageDAO.sqlInsert, values: ["5392a05e30786145d60b0000", "539abf3e307861502f150001", "5392a05e30786145d60b0000", "text", "😀 Emoji enabled", "", "", "", "", 0, 0, 0, 0, "", "", "read", Date()])
        try db.executeUpdate(MessageDAO.sqlInsert, values: ["5392a05e30786145d60b0001", "539abf3e307861502f150001", "5392a05e30786145d60b0000", "photo", "", "", "", "http://demo-resources.oss-cn-beijing.aliyuncs.com/newsdetailsdemo/e3df96cfef1bf9e9355.gif", "gif", 0, 0, 270, 152, "", "", "read", Date()])
    }
}

