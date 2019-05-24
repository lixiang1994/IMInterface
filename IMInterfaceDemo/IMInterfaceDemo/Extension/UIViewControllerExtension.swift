import UIKit

extension UIViewController {

    public func isPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    func alert(_ message: String, actionTitle: String = Localized.DIALOG_BUTTON_OK) {
        let alc = UIAlertController(title: message, message: nil, preferredStyle: UIAlertController.Style.alert)
        alc.addAction(UIAlertAction(title: actionTitle, style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alc, animated: true, completion: nil)
    }

    func alert(_ title: String, message: String?) {
        let alc = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alc.addAction(UIAlertAction(title: Localized.DIALOG_BUTTON_OK, style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alc, animated: true, completion: nil)
    }

    func alert(_ message: String, cancelTitle: String = Localized.DIALOG_BUTTON_CANCEL, actionTitle: String, handler: @escaping ((UIAlertAction) -> Void)) {
        let alc = UIAlertController(title: message, message: nil, preferredStyle: UIAlertController.Style.alert)
        alc.addAction(UIAlertAction(title: cancelTitle, style: UIAlertAction.Style.default, handler: nil))
        alc.addAction(UIAlertAction(title: actionTitle, style: UIAlertAction.Style.destructive, handler: handler))
        self.present(alc, animated: true, completion: nil)
    }
}
