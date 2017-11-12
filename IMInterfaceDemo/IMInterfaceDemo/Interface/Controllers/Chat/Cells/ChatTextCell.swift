import UIKit

class ChatTextCell: ChatCell {
    
    @IBOutlet weak var contentLabel: MessageLabel!
    
    @IBOutlet weak var spacingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        prepareContentLabel()
    }
    
    override func render(item: MessageItem) {
        model = item
        let attributes = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16)]
        let content = NSMutableAttributedString(string: item.content, attributes: attributes)
        let attach = NSTextAttachment()
        attach.bounds = CGRect(x: 0, y: -2, width: item.userId == currentUserId ? 80 : 60, height: 16)
        content.append(NSAttributedString(attachment: attach))
        contentLabel.attributedText = content
        contentLabel.update()
        let image: UIImage?
        if item.userId == currentUserId {
            switch item.status {
            case .sending:
                image = #imageLiteral(resourceName: "ic_sending")
            case .delivered:
                image = #imageLiteral(resourceName: "ic_delivered")
            case .read:
                image = #imageLiteral(resourceName: "ic_read")
            case .failed:
                image = #imageLiteral(resourceName: "ic_sending")
            case .unread:
                image = #imageLiteral(resourceName: "ic_delivered")
            }
        } else {
            image = nil
        }
        configTime(item.createdAt, image)
        layoutIfNeeded()
    }
    
    override func continuity(_ result: Bool) {
        spacingConstraint.constant = result ? 0.0 : 10.0
        layoutIfNeeded()
    }
    
}

extension ChatTextCell: MessageLabelDelegate {
    
    func prepareContentLabel() {
        contentLabel.linkTextColor = UIColor.blue
        contentLabel.selectedBackgroudColor = UIColor(white: 0.8, alpha: 0.5)
        contentLabel.delegate = self
    }
    
    func labelDidSelectedLinkText(label: MessageLabel, text: String) {
        UIApplication.shared.openURL(string: text)
    }
}

