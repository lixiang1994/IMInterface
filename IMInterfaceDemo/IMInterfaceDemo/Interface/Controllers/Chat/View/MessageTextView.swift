import UIKit

class MessageTextView: UITextView {
    
    public weak var overrideNext: UIResponder?
    
    override var next: UIResponder? {
        if let responder = overrideNext {
            return responder
        }
        return super.next
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard overrideNext == nil else {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
