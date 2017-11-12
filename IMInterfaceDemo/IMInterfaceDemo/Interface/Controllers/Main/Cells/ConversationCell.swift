import UIKit
import PINRemoteImage

class ConversationCell: UITableViewCell {

    @IBOutlet weak var iconImageView: AvatarImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    func render(item: ConversationItem) {
        iconImageView.setImage(with: item.iconUrl, identityNumber: item.userIdentityNumber, name: item.name)
        nameLabel.text = item.name
        contentLabel.text = item.content
        timeLabel.text = item.created_at.timeAgo()
    }
    
    func render(messagSearchResult item: MessageSearchResult) {
        iconImageView.setImage(with: item.userAvatarURL, identityNumber: item.userIdentityNumber, name: item.userFullname)
        nameLabel.text = item.userFullname
        contentLabel.text = item.content
        timeLabel.text = item.createdAt.timeAgo()
    }

}
