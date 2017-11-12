import UIKit
import PINRemoteImage
import SnapKit

class AvatarImageView: CornerImageView {

    @IBInspectable
    var titleFontSize: CGFloat = 17 {
        didSet {
            titleLabel?.font = .systemFont(ofSize: titleFontSize)
        }
    }
    var titleLabel: UILabel!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepare()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }
    
    func setImage(with url: String, identityNumber: String, name: String) {
        if let url = URL(string: url) {
            pin_setImage(from: url, placeholderImage: #imageLiteral(resourceName: "ic_place_holder"))
        } else {
            if let number = Int(identityNumber) {
                image = UIImage(named: "color\(number % 24 + 1)")
                backgroundColor = .clear
            } else {
                image = nil
                backgroundColor = UIColor(rgbValue: 0xaaaaaa)
            }
            if let firstLetter = name.first {
                titleLabel.text = String([firstLetter]).uppercased()
            } else {
                titleLabel.text = nil
            }
        }
    }

    private func prepare() {
        titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: titleFontSize)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
}
