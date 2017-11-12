import Foundation

extension JSONDecoder {

    static func instance() -> JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        return jsonDecoder
    }

}

extension Encodable {

    func toJSON() -> String {
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(self) {
            return String(data: jsonData, encoding: .utf8) ?? ""
        }
        return ""
    }

}

extension KeyedDecodingContainer  {

    func getString(key: KeyedDecodingContainer.Key) -> String {
        return contains(key) ? (try? decode(String.self, forKey: key)) ?? "" : ""
    }

    func getBool(key: KeyedDecodingContainer.Key) -> Bool {
        return contains(key) ? (try? decode(Bool.self, forKey: key)) ?? false : false
    }

    func getInt(key: KeyedDecodingContainer.Key) -> Int {
        return contains(key) ? (try? decode(Int.self, forKey: key)) ?? 0 : 0
    }

    func getDate(key: KeyedDecodingContainer.Key) -> Date {
        return contains(key) ? (try? decode(Date.self, forKey: key)) ?? Date() : Date()
    }
}

extension String {

    func toModel<T: Codable>() -> T? {
        let decoder = JSONDecoder.instance()
        if let jsonData = self.data(using: .utf8) {
            return try? decoder.decode(T.self, from: jsonData)
        }
        return nil
    }

}

