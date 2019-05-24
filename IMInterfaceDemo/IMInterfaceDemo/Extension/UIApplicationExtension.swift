import UIKit
import Foundation
import UserNotifications

extension UIApplication {

    class func appDelegate() -> AppDelegate  {
        return UIApplication.shared.delegate as! AppDelegate
    }

    public static func rootNavigationController() -> UINavigationController? {
        return UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
    }

    public static func currentViewController() -> UIViewController? {
        return rootNavigationController()?.visibleViewController
    }
}

extension UIApplication {

    public static func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }

    public func canOpenURL(string: String) -> Bool {
        guard let url = URL(string: string) else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }

    public func openURL(string: String) {
        guard let url = URL(string: string) else {
            return
        }
        UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }

    public func tryOpenURL(_ URLString: String, options: [String: AnyObject] = [:], completionHandler completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: URLString) else {
            return
        }

        guard UIApplication.shared.canOpenURL(url) else {
            return
        }

        UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary(options), completionHandler: completion)
    }
}

extension UIApplication {

    public static func checkNotificationSettings(completionHandler: @escaping (_ authorizationStatus: UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (setting: UNNotificationSettings) in
            DispatchQueue.main.async {
                completionHandler(setting.authorizationStatus)
            }
        })
    }

    public static func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings: UNNotificationSettings) in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { (granted: Bool, error: Error?) in
                    guard granted else {
                        return
                    }
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                })
            } else if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        })
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
