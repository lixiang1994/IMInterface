import Foundation

extension String {

    subscript (i: Int) -> String {
        guard i < count else {
            return ""
        }
        let startIndex = self.index(self.startIndex, offsetBy: i)
        let endIndex = self.index(startIndex, offsetBy: i + 1)
        return String(self[startIndex ..< endIndex])
    }

    func isNumeric() -> Bool {
        return Double(self) != nil
    }
    
    func removeWhiteSpaces() -> String {
        let nsStr = self as NSString
        let fullRange = NSRange(location: 0, length: nsStr.length)
        return nsStr.replacingOccurrences(of: "\\s", with: "", options: .regularExpression, range: fullRange)
    }
    
    func digits() -> String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    func isInteger() -> Bool {
        return self == digits()
    }
    
    func emoji() -> String {
        let base: UInt32 = 127397
        var s = ""
        for v in self.unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return String(s)
    }

    
}
