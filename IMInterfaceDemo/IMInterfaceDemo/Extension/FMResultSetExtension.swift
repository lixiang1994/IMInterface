import FMDB

extension FMResultSet {

    func getString(forColumn: String) -> String {
        return string(forColumn: forColumn) ?? ""
    }

    func getInt(forColumn: String) -> Int {
        return Int(int(forColumn: forColumn))
    }

    func getDate(forColumn: String) -> Date {
        return date(forColumn: forColumn) ?? Date()
    }

}
