import UIKit
import PINRemoteImage

class ChatPhotoCell: ChatCell {
    
    @IBOutlet weak var photoImageView: FLAnimatedImageView!
    
    @IBOutlet weak var spacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        photoImageView.pin_updateWithProgress = true
        photoImageView.isUserInteractionEnabled = true
        photoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapPhotoAction(_:))))
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            photoImageView.alpha = 0.4
        } else {
            photoImageView.alpha = 1.0
        }
    }
    
    @objc func tapPhotoAction(_ recognizer: UITapGestureRecognizer) {
        guard let item = model, let imageUrl = URL(string: item.mediaUrl) else {
            return
        }
        
        let photoBrowser = PhotoBrowserView()
        photoBrowser.delegate = self
        photoBrowser.show(imageUrl: imageUrl, size: CGSize(width: item.mediaWidth, height: item.mediaHeight))
    }
    
    override func render(item: MessageItem) {
        model = item

        guard !item.mediaUrl.isEmpty, item.mediaWidth > 0, item.mediaHeight > 0 else {
            return
        }
        
        let maxWidth: CGFloat = UIScreen.main.bounds.width * 0.7
        let maxHeight: CGFloat = maxWidth
        
        if item.mediaMineType == "gif" {
            photoImageView.layer.cornerRadius = 6.0
            photoImageView.layer.masksToBounds = true
            photoImageView.pin_setImage(from: URL(string: item.mediaUrl), placeholderImage: #imageLiteral(resourceName: "ic_place_holder"))
        } else {
            photoImageView.layer.cornerRadius = 0.0
            photoImageView.layer.masksToBounds = false
            photoImageView.pin_setImage(from: URL(string: item.mediaUrl), placeholderImage: #imageLiteral(resourceName: "ic_place_holder"), processorKey: "message") { (result, unsafePointer) -> UIImage? in
                guard let image = result.image else {
                    return result.image
                }
                let cornerRadius = 6.0
                let ratio = image.size.height / image.size.width
                let width =  maxWidth
                let height = width * ratio
                let size = CGSize(width: width, height: height)
                let finalSize = CGSize(width: width, height: min(height, maxWidth))
                let shadowSize = CGSize(width: 140.0, height: 40.0)
                let shadowImage = #imageLiteral(resourceName: "ic_message_photo_shadow")
                
                UIGraphicsBeginImageContextWithOptions(finalSize, false, UIScreen.main.scale)
                let bezierPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint.zero, size: finalSize), cornerRadius: CGFloat(cornerRadius))
                bezierPath.addClip()
                image.draw(in: CGRect(origin: CGPoint(x: 0, y: -(height - finalSize.height) * 0.5), size: size))
                shadowImage.draw(in: CGRect(origin: CGPoint(x: finalSize.width - shadowSize.width, y: finalSize.height - shadowSize.height), size: shadowSize))
                let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                return resultImage
            }
        }
        
        let imageWitdh = CGFloat(item.mediaWidth)
        let imageHeight = CGFloat(item.mediaHeight)
        if imageWitdh > 0.0 && imageHeight > 0.0 {
            let ratio = imageHeight / imageWitdh
            let height = maxWidth * ratio
            photoWidthConstraint.constant = maxWidth
            photoHeightConstraint.constant = height > maxHeight ? maxHeight : height
            layoutIfNeeded()
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
        configTime(item.createdAt, image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate))
    }
    
    override func continuity(_ result: Bool) {
        spacingConstraint.constant = result ? 0.0 : 10.0
        layoutIfNeeded()
    }
    
}

extension ChatPhotoCell: PhotoBrowserDelegate {
    
    func originalRect() -> CGRect {
        guard let window = self.window else {
            return CGRect.zero
        }
        return window.convert(photoImageView.frame, from: photoImageView.superview)
    }
    
    func openBrowser() {
        containerView.isHidden = true
    }
    
    func closeBrowser() {
        containerView.isHidden = false
    }
}
