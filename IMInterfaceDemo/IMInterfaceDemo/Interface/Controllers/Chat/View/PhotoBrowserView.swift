import UIKit
import PINCache
import PINRemoteImage

protocol PhotoBrowserDelegate: class {
    func originalRect() -> CGRect
    func openBrowser()
    func closeBrowser()
}

class PhotoBrowserView: UIView {
    
    weak var delegate: PhotoBrowserDelegate?
    
    private let browserScrollView = UIScrollView()
    private let browserImageView = FLAnimatedImageView()
    private var isLongImage = false
    private var imageSizeRatio: CGFloat = 0.0
    
    func show(imageUrl: URL, size: CGSize) {
        guard let imageRect = delegate?.originalRect() , let window = UIApplication.shared.delegate?.window else {
            return
        }
        
        self.frame = UIScreen.main.bounds
        backgroundColor = UIColor.clear
        window?.endEditing(true)
        window?.addSubview(self)
        browserScrollView.layer.masksToBounds = true
        browserScrollView.frame = bounds
        browserScrollView.contentSize = bounds.size
        browserScrollView.zoomScale = 1.0
        browserScrollView.maximumZoomScale = 3.0
        browserScrollView.minimumZoomScale = 1.0
        browserScrollView.delegate = self
        addSubview(browserScrollView)
        browserImageView.layer.cornerRadius = 6.0
        browserImageView.layer.masksToBounds = true
        browserImageView.layer.shadowColor = UIColor.black.cgColor
        browserImageView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        browserImageView.layer.shadowRadius = 4.0
        browserImageView.layer.shadowOpacity = 0.6
        browserImageView.contentMode = UIView.ContentMode.scaleAspectFill
        browserImageView.frame = imageRect
        browserScrollView.addSubview(browserImageView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBrowserAction(_:)))
        addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(browserImagePanAction(_ :)))
        browserImageView.addGestureRecognizer(pan)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(browserImageDoubleTapAction(_ :)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        tap.require(toFail: doubleTap)
        browserImageView.addGestureRecognizer(doubleTap)
        
        let key = PINRemoteImageManager.shared().cacheKey(for: imageUrl, processorKey: nil)
        PINRemoteImageManager.shared().imageFromCache(withCacheKey: key, options: PINRemoteImageManagerDownloadOptions(rawValue: 0)) { [weak self] (result) in
            guard let weakSelf = self else {
                return
            }
            DispatchQueue.main.async {
                if let image = result.image {
                    weakSelf.browserImageView.image = image
                } else {
                    weakSelf.browserImageView.pin_setImage(from: imageUrl, placeholderImage: #imageLiteral(resourceName: "ic_place_holder"))
                }
                weakSelf.delegate?.openBrowser()
                UIView.animate(withDuration: 0.2, animations: {
                    weakSelf.backgroundColor = UIColor.black
                    let ratio = size.height / size.width
                    let width = UIScreen.main.bounds.width
                    let height = UIScreen.main.bounds.width * ratio
                    weakSelf.imageSizeRatio = ratio
                    weakSelf.browserImageView.layer.cornerRadius = 0.0
                    weakSelf.browserImageView.layer.masksToBounds = false
                    weakSelf.browserImageView.frame = CGRect(x: 0, y: (UIScreen.main.bounds.height - height) * 0.5, width: width, height: height)
                    weakSelf.browserScrollView.contentSize = weakSelf.browserImageView.frame.size
                    if weakSelf.browserImageView.frame.height > weakSelf.browserScrollView.frame.height {
                        weakSelf.browserImageView.center = CGPoint(x: weakSelf.browserScrollView.contentSize.width * 0.5, y: weakSelf.browserScrollView.contentSize.height * 0.5)
                        weakSelf.isLongImage = true
                    } else {
                        weakSelf.browserImageView.center = CGPoint(x: weakSelf.browserScrollView.frame.width * 0.5, y: weakSelf.browserScrollView.frame.height * 0.5)
                        weakSelf.isLongImage = false
                    }
                }, completion: { (finish) in
                    weakSelf.browserImageView.isUserInteractionEnabled = !weakSelf.isLongImage
                })
            }
        }
    }
    
    private func close() {
        guard let imageRect = delegate?.originalRect() else {
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundColor = UIColor.clear
            self.browserScrollView.contentSize = self.browserScrollView.bounds.size
            self.browserScrollView.zoomScale = 1.0
            self.browserImageView.frame = imageRect
            self.browserImageView.layer.cornerRadius = 6.0
            self.browserImageView.layer.masksToBounds = true
        }) { (isFinish) in
            self.removeFromSuperview()
            self.delegate?.closeBrowser()
        }
    }
    
    @objc func browserImageDoubleTapAction(_ recognizer: UIPanGestureRecognizer) {
        UIView.animate(withDuration: 0.2) {
            if self.browserScrollView.zoomScale == 1.0 {
                self.browserScrollView.zoomScale = 1.8
            } else {
                self.browserScrollView.zoomScale = 1.0
            }
        }
    }
    
    @objc func browserImagePanAction(_ recognizer: UIPanGestureRecognizer) {
        guard browserScrollView.zoomScale == 1.0 else {
            return
        }
        let scaleRange: CGFloat = bounds.height * 0.2
        let closeRange: CGFloat = 50.0
        let point = recognizer.translation(in: browserScrollView)
        let range = abs(browserScrollView.center.y - browserImageView.center.y)
        switch recognizer.state {
        case .changed:
            if let imageRect = delegate?.originalRect() {
                let scaleRangeRatio = range / scaleRange < 1.0 ? range / scaleRange : 1.0
                let width = (UIScreen.main.bounds.width - imageRect.width) * (1.0 - scaleRangeRatio)
                let height = (UIScreen.main.bounds.width * imageSizeRatio - imageRect.height) * (1.0 - scaleRangeRatio)
                browserImageView.bounds.size = CGSize(width: imageRect.width + width, height: imageRect.height + height)
            }
            let x = browserImageView.center.x + point.x
            let y = browserImageView.center.y + point.y
            browserImageView.center = CGPoint(x: x, y: y)
            backgroundColor = UIColor.black.withAlphaComponent(1.0 - (range / closeRange))
        case .ended:
            if (range < closeRange) {
                UIView.animate(withDuration: 0.2, animations: {
                    self.browserImageView.transform = CGAffineTransform.identity
                    self.browserImageView.bounds.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * self.imageSizeRatio)
                    self.browserImageView.center = self.browserScrollView.center
                    self.backgroundColor = UIColor.black
                })
            } else {
                close()
            }
        default:
            break
        }
        recognizer.setTranslation(CGPoint.zero, in: browserScrollView)
    }
    
    @objc func tapBrowserAction(_ recognizer: UITapGestureRecognizer) {
        close()
    }
}

extension PhotoBrowserView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return browserImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let delta_x = scrollView.bounds.size.width > scrollView.contentSize.width ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0
        let delta_y = scrollView.bounds.size.height > scrollView.contentSize.height ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0
        browserImageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + delta_x, y: scrollView.contentSize.height * 0.5 + delta_y)
    }
}
