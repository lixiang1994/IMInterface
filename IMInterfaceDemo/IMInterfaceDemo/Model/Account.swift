import Foundation

struct Account: Codable {

    enum AccountType: String, Codable {
        case user
    }
    
    let type: AccountType
    let id: String
    let identity_number: String
    let full_name: String
    let avatar_url: String
    let phone: String
    let authentication_token: String
    let invitation_code: String
    let consumed_count: Int
    let qrcode_url: String
    
}
