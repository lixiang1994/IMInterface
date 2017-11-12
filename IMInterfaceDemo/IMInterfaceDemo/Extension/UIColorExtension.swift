import UIKit

extension UIColor {

    static let theme = UIColor(rgbValue: 0x19c2fd)
    static let backgroundGray = UIColor(rgbValue: 0xf5f5f5)
    static let error = UIColor(rgbValue: 0xd73449)

    convenience init(rgbValue: UInt, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0, blue: CGFloat(rgbValue & 0x0000FF) / 255.0, alpha: alpha)
    }

    var image: UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        var image: UIImage?
        UIGraphicsBeginImageContext(rect.size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(cgColor)
            context.fill(rect)
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return image
    }
    
}
