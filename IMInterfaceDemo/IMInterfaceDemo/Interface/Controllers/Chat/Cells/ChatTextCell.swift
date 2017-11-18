import UIKit
import YYText

class ChatTextCell: ChatCell {
    
    @IBOutlet weak var contentLabel: MessageLabel!
    
    @IBOutlet weak var spacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        prepareContentLabel()
    }
    
    override func render(item: MessageItem) {
        model = item
        let font = UIFont.systemFont(ofSize: 16)
        let attributes = [NSAttributedStringKey.font : font]
        let content = NSMutableAttributedString(string: item.content, attributes: attributes)
        let placeLayer = CALayer()
        placeLayer.frame = CGRect(x: 0, y: 0, width: item.userId == currentUserId ? 80 : 60, height: font.pointSize)
        let attach = NSMutableAttributedString.yy_attachmentString(withContent: placeLayer, contentMode: UIViewContentMode.bottomRight, attachmentSize: placeLayer.frame.size, alignTo: font, alignment: YYTextVerticalAlignment.center)
        content.append(attach)
        contentLabel.textHandle(text: content)
        contentLabel.attributedText = content
        if let text = contentLabel.attributedText {
            let size = contentLabel.textSize(text: text, size: CGSize(width: UIScreen.main.bounds.width - 80, height: CGFloat(MAXFLOAT)))
            contentWidthConstraint.constant = size.width
            contentHeightConstraint.constant = size.height
        }
        
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
        contentLabel.delegate = self
    }
    
    func labelDidSelectedLinkText(label: MessageLabel, text: String, type: LinkType) {
        switch type {
        case .email:
            print(text)
        case .phone:
            print(text)
        case .url:
            UIApplication.shared.openURL(string: text)
        }
    }
}

