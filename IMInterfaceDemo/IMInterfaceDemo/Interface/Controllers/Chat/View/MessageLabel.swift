import UIKit

protocol MessageLabelDelegate: class {
    func labelDidSelectedLinkText(label: MessageLabel, text: String)
}

class MessageLabel: UILabel {

    private let patterns = ["((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)" , "@[\\u4e00-\\u9fa5a-zA-Z0-9_-]*"]

    private lazy var linkRanges = [NSRange]()
    private lazy var tempAttributedString = NSMutableAttributedString()
    private lazy var layoutManager = NSLayoutManager()
    private lazy var textContainer = NSTextContainer()

    var linkTextColor = UIColor.blue
    var selectedBackgroudColor = UIColor.lightGray

    private var selectedRange: NSRange?

    weak var delegate: MessageLabelDelegate?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        prepareLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareLabel()
    }
    
    public func update() {
        updateAttributedString()
    }
    
    private func updateAttributedString() {
        if attributedText == nil {
            attributedText = NSAttributedString(string: text ?? "")
        }
        let attrStringM = addLineBreak(attributedText!)
        regexLinkRanges(attrStringM)
        addLinkAttribute(attrStringM)
        tempAttributedString = NSMutableAttributedString(attributedString: attrStringM)
        attributedText = tempAttributedString
    }
    
    private func addLinkAttribute(_ attrStringM: NSMutableAttributedString) {
        guard attrStringM.length != 0 else {
            return
        }
        var range = NSRange(location: 0, length: 0)
        var attributes = attrStringM.attributes(at: 0, effectiveRange: &range)
        attributes[NSAttributedStringKey.font] = font
        attributes[NSAttributedStringKey.foregroundColor] = textColor
        attrStringM.addAttributes(attributes, range: range)
        attributes[NSAttributedStringKey.foregroundColor] = linkTextColor
        for r in linkRanges {
            attrStringM.setAttributes(attributes, range: r)
        }
    }
    
    private func regexLinkRanges(_ attrString: NSAttributedString) {
        linkRanges.removeAll()
        let regexRange = NSRange(location: 0, length: attrString.string.count)
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.dotMatchesLineSeparators) else{
                continue
            }
            let results = regex.matches(in: attrString.string, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: regexRange)
            for r in results {
                linkRanges.append(r.range(at: 0))
            }
        }
    }
    
    private func addLineBreak(_ attrString: NSAttributedString) -> NSMutableAttributedString {
        let attrStringM = NSMutableAttributedString(attributedString: attrString)
        if attrStringM.length == 0 {
            return attrStringM
        }
        var range = NSRange(location: 0, length: 0)
        var attributes = attrStringM.attributes(at: 0, effectiveRange: &range)

        if let paragraphStyle = attributes[NSAttributedStringKey.paragraphStyle] as? NSMutableParagraphStyle {
            paragraphStyle.lineBreakMode = .byWordWrapping
        } else {
            let paragraphStyleM = NSMutableParagraphStyle()
            paragraphStyleM.lineBreakMode = .byWordWrapping
            attributes[NSAttributedStringKey.paragraphStyle] = paragraphStyleM
            attrStringM.setAttributes(attributes, range: range)
        }
        return attrStringM
    }
    
    private func glyphsRange() -> NSRange {
        return NSRange(location: 0, length: tempAttributedString.length)
    }
    
    private func glyphsOffset(_ range: NSRange) -> CGPoint {
        let rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
        let height = (bounds.height - rect.height) * 0.5
        return CGPoint(x: 0, y: height)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let location = touches.first?.location(in: self) else {
            return
        }
        selectedRange = linkRangeAtLocation(location)
        modifySelectedAttribute(true)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let location = touches.first?.location(in: self) else {
            return
        }
        if let range = linkRangeAtLocation(location) {
            if !(range.location == selectedRange?.location && range.length == selectedRange?.length) {
                modifySelectedAttribute(false)
                selectedRange = range
                modifySelectedAttribute(true)
            }
        } else {
            modifySelectedAttribute(false)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let range = selectedRange else {
            return
        }
        let text = (tempAttributedString.string as NSString).substring(with: range)
        delegate?.labelDidSelectedLinkText(label: self, text: text)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
            self.modifySelectedAttribute(false)
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        modifySelectedAttribute(false)
    }
    
    private func modifySelectedAttribute(_ isSet: Bool) {
        guard let range = selectedRange else {
            return
        }
        var attributes = tempAttributedString.attributes(at: 0, effectiveRange: nil)
        attributes[NSAttributedStringKey.foregroundColor] = linkTextColor
        attributes[NSAttributedStringKey.backgroundColor] = isSet ? selectedBackgroudColor : UIColor.clear
        tempAttributedString.addAttributes(attributes, range: range)
        selectedRange = isSet ? selectedRange : nil
        attributedText = tempAttributedString
    }
    
    private func linkRangeAtLocation(_ location: CGPoint) -> NSRange? {
        guard tempAttributedString.length != 0 else {
            return nil
        }

        let offset = glyphsOffset(glyphsRange())
        let point = CGPoint(x: offset.x + location.x, y: offset.y + location.y)
        let index = layoutManager.glyphIndex(for: point, in: textContainer)
        for r in linkRanges {
            if  NSLocationInRange(index, r) { //index >= r.location && index <= r.location + r.length
                return r
            }
        }
        return nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = bounds.size
    }
    
    private func prepareLabel() {
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        isUserInteractionEnabled = true
    }
}
