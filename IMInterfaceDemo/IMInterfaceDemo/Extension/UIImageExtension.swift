import UIKit

extension UIImage {
    
    func getData() -> Data? {
        let alphaInfo = self.cgImage?.alphaInfo
        let hasAlpha = !(alphaInfo == CGImageAlphaInfo.none ||
            alphaInfo == CGImageAlphaInfo.noneSkipFirst ||
            alphaInfo == CGImageAlphaInfo.noneSkipLast)
        
        let usePNG = hasAlpha
        if usePNG {
            return UIImagePNGRepresentation(self)!
        } else {
            return UIImageJPEGRepresentation(self, 1.0)!
        }
    }
}
