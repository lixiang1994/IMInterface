import Foundation
import Alamofire
import UserNotifications

final class AccountAPI: BaseAPI {
    
    static let shared = AccountAPI()
    
    private let avatarJPEGCompressionQuality: CGFloat = 0.8
    private let accountStorageKey = "Account"
    
    private var _account: Account?
    private lazy var jsonEncoder = JSONEncoder()
    
    var account: Account? {
        get {
            if let account = _account {
                return account
            } else if let data = UserDefaults.standard.value(forKey: accountStorageKey) as? Data, let account = try? BaseAPI.jsonDecoder.decode(Account.self, from: data) {
                _account = account
                BaseAPI.headersAuthorizationValue = account.authentication_token
                return account
            } else {
                self.account = Account(type: Account.AccountType.user, id: "123456", identity_number: "1994", full_name: "LEE", avatar_url: "", phone: "186****1994", authentication_token: "qwertyuiopasdfghjklzxcvbnm", invitation_code: "1234", consumed_count: 0, qrcode_url: "http://www.lee1994.com")
                return _account
            }
        }
        set {
            _account = newValue
            let userDefaults = UserDefaults.standard
            if let account = newValue {
                if let data = try? jsonEncoder.encode(account) {
                    userDefaults.setValue(data, forKey: accountStorageKey)
                }
            } else {
                userDefaults.removeObject(forKey: accountStorageKey)
            }
            userDefaults.synchronize()
            BaseAPI.headersAuthorizationValue = _account?.authentication_token
        }
    }
    
}
