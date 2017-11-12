import UIKit

extension NotificationCenter {

    func postOnMain(name: NSNotification.Name, object: Any? = nil) {
        if Thread.isMainThread {
            post(name: name, object: object)
        } else {
            DispatchQueue.main.async {
                self.post(name: name, object: object)
            }
        }
    }

}
