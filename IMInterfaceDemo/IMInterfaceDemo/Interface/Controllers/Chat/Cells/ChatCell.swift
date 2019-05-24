import UIKit
import SnapKit
protocol ChatCellDelegate: class {
    func longPressMenu(cell: ChatCell, item: MessageItem, rect: CGRect)
}

class ChatCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bubbleImageView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!

    internal var model: MessageItem?
    
    var currentUserId = AccountAPI.shared.account?.id ?? ""
    
    weak var delegate: ChatCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.clear
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.clear
        selectedBackgroundView = selectedView

        let long = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_ :)))
        long.minimumPressDuration =  0.8
        addGestureRecognizer(long)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willHideMenu(_:)), name: UIMenuController.willHideMenuNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func willHideMenu(_ notify: Notification) {
        setSelected(false, animated: true)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            bubbleImageView.alpha = 0.4
        } else {
            bubbleImageView.alpha = 1.0
        }
    }

    @objc func longPressAction(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == UIGestureRecognizer.State.began, let delegate = delegate, let item = model else {
            return
        }

        delegate.longPressMenu(cell: self, item: item, rect: containerView.frame)
        setSelected(true, animated: true)
    }

    func render(item: MessageItem) {
        
    }
    
    func continuity(_ result: Bool) {
        
    }
    
    func last(_ result: Bool) {
        bubbleImageView.isHighlighted = result
    }
    
    func configTime(_ date: Date, _ image: UIImage?) {
        let formatter = DateFormatter(dateFormat: "hh:mm a")
        formatter.locale = Locale(identifier: "en_US")
        let timeString = formatter.string(from: date)
        let time = NSMutableAttributedString(string: timeString, attributes: [NSAttributedString.Key.font : timeLabel.font , NSAttributedString.Key.foregroundColor : timeLabel.textColor])
        if let image = image {
            let size = image.size
            let ratio = size.width / size.height
            let attach = NSTextAttachment()
            attach.image = image
            attach.bounds = CGRect(x: 0, y: -1, width: 10 * ratio, height: 10)
            time.append(NSAttributedString(string: "  "))
            time.append(NSAttributedString(attachment: attach))
        }
        timeLabel.attributedText = time
    }
}
