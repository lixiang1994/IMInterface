import UIKit

class ChatTimeHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var timeLabel: UILabel!
    
    public func render(time: String) {
        let formatter = DateFormatter(dateFormat: "yyyyMMdd")
        formatter.locale = Locale.current
        if let date = formatter.date(from: time) {
            let seconds = Date().timeIntervalSince(date)
            let days = seconds / 86400
            
            if days < 1 {
                timeLabel.text = Localized.CHAT_TIME_TODAY
            } else if days < 7 {
                let formatter = DateFormatter(dateFormat: "EEEE")
                timeLabel.text = formatter.string(from: date).capitalized
            } else {
                if date.isThisYear() {
                    let formatter = DateFormatter(dateFormat: "MMMM d EEEE")
                    timeLabel.text = formatter.string(from: date)
                } else {
                    let formatter = DateFormatter(dateFormat: "YYYY MMMM d")
                    timeLabel.text = formatter.string(from: date)
                }
            }
        }
    }
}
