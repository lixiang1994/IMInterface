import UIKit

extension UIViewController {

    public func isPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    func alert(_ message: String, actionTitle: String = Localized.DIALOG_BUTTON_OK) {
        let alc = UIAlertController(title: message, message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alc.addAction(UIAlertAction(title: actionTitle, style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alc, animated: true, completion: nil)
    }

    func alert(_ title: String, message: String?) {
        let alc = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alc.addAction(UIAlertAction(title: Localized.DIALOG_BUTTON_OK, style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alc, animated: true, completion: nil)
    }

    func alert(_ message: String, cancelTitle: String = Localized.DIALOG_BUTTON_CANCEL, actionTitle: String, handler: @escaping ((UIAlertAction) -> Void)) {
        let alc = UIAlertController(title: message, message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alc.addAction(UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.default, handler: nil))
        alc.addAction(UIAlertAction(title: actionTitle, style: UIAlertActionStyle.destructive, handler: handler))
        self.present(alc, animated: true, completion: nil)
    }
}
