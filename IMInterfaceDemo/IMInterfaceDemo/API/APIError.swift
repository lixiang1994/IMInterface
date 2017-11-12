import Foundation

struct APIError: Encodable {
    
    let code: Int
    let status: Int // HTTP Status Code in most cases
    let description: String?
    let kind: Kind
    
    init(code: Int, status: Int, description: String?) {
        self.init(code: code, status: status, description: description, kind: Kind(code: code))
    }
    
    init(code: Int, status: Int, description: String?, kind: Kind) {
        self.code = code
        self.status = status
        self.description = description
        self.kind = kind
    }
    
}

extension APIError: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case code
        case status
        case description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        status = try container.decode(Int.self, forKey: .status)
        description = try container.decode(String.self, forKey: .description)
        kind = Kind(code: code)
    }
    
}

extension APIError {
    
    static let invalidCode = -999999
    
    static func badResponse(status: Int, description: String?) -> APIError {
        return self.init(code: invalidCode, status: status, description: description, kind: .badResponse)
    }
    
    static func jsonDecodingFailed(status: Int, description: String?) -> APIError {
        return self.init(code: invalidCode, status: status, description: description, kind: .jsonDecodingFailed)
    }
    
}

extension APIError {
    
    enum Kind {
        // System
        case cancelled
        case notConnectedToInternet
        case timedOut
        // Bad response
        case badResponse
        case jsonDecodingFailed
        // Minewave
        case badRequest
        case invalidAPITokenHeader
        case invalidUserTokenHeader
        case forbidden
        case notFound
        case tooManyRequests
        case internalServerError
        case phoneVerificationInvalid
        case reachedFriendLimit
        // 
        case invalidInvitationCode
        case invalidVerificationCode
        // Unhandled
        case unhandled
        
        init(code: Int) {
            switch code {
            case NSURLErrorCancelled:
                self = .cancelled
            case NSURLErrorNotConnectedToInternet:
                self = .notConnectedToInternet
            case NSURLErrorTimedOut:
                self = .timedOut
            case 400:
                self = .badRequest
            case 401:
                self = .invalidAPITokenHeader
            case 402:
                self = .invalidUserTokenHeader
            case 403:
                self = .forbidden
            case 404:
                self = .notFound
            case 429:
                self = .tooManyRequests
            case 10500:
                self = .internalServerError
            case 12013:
                self = .phoneVerificationInvalid
            case 12031:
                self = .reachedFriendLimit
            case 20112:
                self = .invalidInvitationCode
            case 20113:
                self = .invalidVerificationCode
            default:
                self = .unhandled
            }
        }
    }
    
}
