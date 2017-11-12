import Foundation
import KeychainAccess

extension Keychain {

    class func getDeviceId() -> String {
        let keychain = Keychain(service: "one.mixin.ios.notifications")
        var device_id = keychain["device_id"] ?? ""
        if device_id.isEmpty {
            device_id = UUID().uuidString
            keychain["device_id"] = device_id
        }
        return device_id
    }

}
