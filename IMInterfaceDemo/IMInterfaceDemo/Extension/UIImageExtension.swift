import UIKit

extension UIImage {
    
    func getData() -> Data? {
        let alphaInfo = self.cgImage?.alphaInfo
        let hasAlpha = !(alphaInfo == CGImageAlphaInfo.none ||
            alphaInfo == CGImageAlphaInfo.noneSkipFirst ||
            alphaInfo == CGImageAlphaInfo.noneSkipLast)
        
        let usePNG = hasAlpha
        if usePNG {
            return self.pngData()!
        } else {
            return self.jpegData(compressionQuality: 1.0)!
        }
    }
}
