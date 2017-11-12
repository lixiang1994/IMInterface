import UIKit
import PINCache
import PINRemoteImage
import TZImagePickerController

class ChatViewController: UIViewController {

    private let textCellIdentifier = "cell_identifier_text"
    private let textMeCellIdentifier = "cell_identifier_text_me"
    private let photoCellIdentifier = "cell_identifier_photo"
    private let photoMeCellIdentifier = "cell_identifier_photo_me"
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: MessageTextView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    
    private var currentUserId = AccountAPI.shared.account?.id ?? ""
    private var isDidAppear = false
    private var isShowedKeyboard = false
    private var currentContentOffsetY: CGFloat = 0.0
    
    private var groupInfo: [String : [MessageItem]] = [:]
    private var groupSort: [String] = []
    private var selectedMessage: MessageItem?
    private var conversation: ConversationItem?
    private var user: User?
    private var conversationId: String?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isDidAppear = true
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        isDidAppear = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareTableView()
        prepareTextView()
        fetchData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(messageDidChange(_:)), name: NSNotification.Name.MessageDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func fetchData() {
        if let conversation = self.conversation {
            conversationId = conversation.id
            renderInfo(avatarUrl: conversation.iconUrl, identityNumber: conversation.userIdentityNumber, name: conversation.name)
            DispatchQueue.global().async { [weak self] in
                let messages = MessageDAO.shared.getMessages(conversationId: conversation.id)
                self?.timeGroupingHandle(messages)
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.scrollToBottom(false)
                }
            }
        } else if let user = self.user {
            renderInfo(avatarUrl: user.avatar_url, identityNumber: user.identity_number, name: user.full_name)
            DispatchQueue.global().async { [weak self] in
                if let conversationId = ConversationDAO.shared.getConversationIdIfExists(userId: user.id) {
                    self?.conversationId = conversationId
                    let messages = MessageDAO.shared.getMessages(conversationId: conversationId)
                    self?.timeGroupingHandle(messages)
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                        self?.scrollToBottom(false)
                    }
                } else {
                    self?.conversationId = ConversationDAO.shared.addContactCoversation(name: user.full_name, iconUrl: user.avatar_url, userId: user.id)
                }
            }
        }
    }
    
    func timeGroupingHandle(_ messages: [MessageItem]) {
        let formatter = DateFormatter(dateFormat: "yyyyMMdd")
        formatter.locale = Locale.current
        for item in messages {
            var array = groupInfo[formatter.string(from: item.createdAt)] ?? []
            array.append(item)
            groupInfo[formatter.string(from: item.createdAt)] = array
        }
        groupSort = groupInfo.keys.sorted(by:<)
    }

    private func renderInfo(avatarUrl: String, identityNumber: String, name: String) {
        title = name
    }
    
    private func scrollToBottom(_ animated: Bool) {
        guard let lastKey = groupSort.last, let array = groupInfo[lastKey] else {
            return
        }
        
        let indexPath = IndexPath(row: array.count - 1, section: groupSort.count - 1)
        tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: animated)
    }
    
    @IBAction func transferAction(_ sender: Any) {
        
    }
    
    @IBAction func photoAction(_ sender: Any) {
        let alc = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alc.addAction(UIAlertAction(title: Localized.CHAT_ACTION_TITLE_CAMERA, style: .default, handler: { [weak self] (action) in
            self?.openCamera()
        }))
        alc.addAction(UIAlertAction(title: Localized.CHAT_ACTION_TITLE_ALBUM, style: .default, handler: { [weak self] (action) in
            self?.openAlbum()
        }))
        alc.addAction(UIAlertAction(title: Localized.DIALOG_BUTTON_CANCEL, style: .cancel, handler: nil))
        self.present(alc, animated: true, completion: nil)
    }
    
    @IBAction func sendAction(_ sender: Any) {
        guard let content = textView.text?.trimmingCharacters(in: CharacterSet.whitespaces), !content.isEmpty else {
            return
        }
        guard let account = AccountAPI.shared.account else {
            return
        }

        guard let conversationId = self.conversationId else {
            return
        }

        clearTextView()
        var message = MessageItem(messageId: UUID().uuidString, conversationId: conversationId, content: content)
        message.userId = account.id
        message.userFullName = account.full_name
        message.userIdentityNumber = account.identity_number
        MessageDAO.shared.sendMessage(message: message)
    }

    @objc func messageDidChange(_ sender: Notification) {
        guard let message = sender.object as? MessageItem, message.conversationId == conversationId else {
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale.current
        let key = formatter.string(from: message.createdAt)
        if let section = groupSort.index(where: { (item) -> Bool in return item == key }) {
            var array = groupInfo[key] ?? []
            if let lastMessage = array.last, lastMessage.userId == message.userId {
                let row = array.count - 1
                let indexPath = IndexPath(row: row, section: section)
                if let lastCell = tableView.cellForRow(at: indexPath) as? ChatCell {
                    lastCell.last(false)
                }
            }
            array.append(message)
            groupInfo[key] = array
            let row = array.count - 1
            let indexPath = IndexPath(row: row, section: section)
            tableView.beginUpdates()
            tableView.insertRows(at: [indexPath], with: .none)
            tableView.endUpdates()
        } else {
            groupInfo[key] = [message]
            groupSort.append(key)
            let section = groupSort.count - 1
            let indexPath = IndexPath(row: 0, section: section)
            tableView.beginUpdates()
            tableView.insertSections(IndexSet(integer: section), with: .none)
            tableView.insertRows(at: [indexPath], with: .none)
            tableView.endUpdates()
        }
        if message.userId == currentUserId  {
            scrollToBottom(false)
            currentContentOffsetY = tableView.contentOffset.y
        }
    }

    class func instance(conversation: ConversationItem? = nil, user: User? = nil) -> UIViewController {
        let vc = Storyboard.chat.instantiateViewController(withIdentifier: "chat") as! ChatViewController
        vc.conversation = conversation
        vc.user = user
        return vc
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {

    private func prepareTableView() {
        tableView.register(UITableViewHeaderFooterView.classForCoder(), forHeaderFooterViewReuseIdentifier: "footer")
        tableView.register(UINib(nibName: "ChatTimeHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
        tableView.register(UINib(nibName: "ChatLeftTextCell", bundle: nil), forCellReuseIdentifier: textCellIdentifier)
        tableView.register(UINib(nibName: "ChatRightTextCell", bundle: nil), forCellReuseIdentifier: textMeCellIdentifier)
        tableView.register(UINib(nibName: "ChatLeftPhotoCell", bundle: nil), forCellReuseIdentifier: photoCellIdentifier)
        tableView.register(UINib(nibName: "ChatRightPhotoCell", bundle: nil), forCellReuseIdentifier: photoMeCellIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapTableView(recognizer:)))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
    }
    
    @objc func tapTableView(recognizer: UITapGestureRecognizer) {
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        }
        UIMenuController.shared.setMenuVisible(false, animated: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        currentContentOffsetY = tableView.contentOffset.y
        UIMenuController.shared.setMenuVisible(false, animated: false)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return groupSort.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let array = groupInfo[groupSort[section]] else {
            return 0
        }
        return array.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UIView.setAnimationsEnabled(false)
        let array = groupInfo[groupSort[indexPath.section]] ?? []
        let message: MessageItem = array[indexPath.row]
        let isMe = message.userId == currentUserId
        let cellIdentifier: String?
        switch message.type {
        case .text:
            cellIdentifier = isMe ? textMeCellIdentifier : textCellIdentifier
        case .photo:
            cellIdentifier = isMe ? photoMeCellIdentifier : photoCellIdentifier
        case .video:
            cellIdentifier = ""
        case .sticker:
            cellIdentifier = ""
        case .card_contact:
            cellIdentifier = ""
        case .card_group:
            cellIdentifier = ""
        case .card_transfer:
            cellIdentifier = ""
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier!) as! ChatCell
        cell.delegate = self
        cell.render(item: message)
        if indexPath.row < array.count - 1 {
            let nextMessage = array[indexPath.row + 1]
            let isEqual = message.userId == nextMessage.userId
            cell.last(!isEqual)
        } else {
            cell.last(true)
        }
        if indexPath.row > 0 {
            let lastMessage = array[indexPath.row - 1]
            let isEqual = message.userId == lastMessage.userId
            cell.continuity(isEqual)
        } else {
            cell.continuity(false)
        }
        UIView.setAnimationsEnabled(true)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view: ChatTimeHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as! ChatTimeHeaderView
        view.render(time: groupSort[section])
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "footer")
        if let backgroundView = view?.backgroundView {
            backgroundView.backgroundColor = UIColor.clear
        } else {
            view?.backgroundView = UIView()
        }
        return view
    }
}

extension ChatViewController: ChatCellDelegate {
    
    func longPressMenu(cell: ChatCell, item: MessageItem, rect: CGRect) {
        if textView.isFirstResponder {
            textView.overrideNext = self
            NotificationCenter.default.addObserver(self, selector: #selector(willHideMenu(_:)), name: NSNotification.Name.UIMenuControllerWillHideMenu, object: nil)
        } else {
            becomeFirstResponder()
        }
        selectedMessage = item
        let copyItem = UIMenuItem(title: Localized.CHAT_MESSAGE_MENU_COPY, action: #selector(copyAction(_:)))
        let forwardItem = UIMenuItem(title: Localized.CHAT_MESSAGE_MENU_FORWARD, action: #selector(forwardAction(_:)))
        let deleteItem = UIMenuItem(title: Localized.CHAT_MESSAGE_MENU_DELETE, action: #selector(deleteAction(_:)))
        let menuController = UIMenuController.shared
        menuController.menuItems = [copyItem, forwardItem, deleteItem]
        menuController.setTargetRect(rect, in: cell.contentView)
        menuController.setMenuVisible(true, animated: true)
    }
    
    @objc func willHideMenu(_ notify: Notification) {
        selectedMessage = nil
        textView.overrideNext = nil
        UIMenuController.shared.menuItems = nil
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIMenuControllerWillHideMenu, object: nil)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return  action == #selector(copyAction(_:)) ||
            action == #selector(forwardAction(_:)) ||
            action == #selector(deleteAction(_:))
    }
    
    @objc func copyAction(_ sender: Any) {
        guard let item = selectedMessage else {
            return
        }
        DispatchQueue.global().async {
            UIPasteboard.general.string = item.content
        }
    }
    
    @objc func forwardAction(_ sender: Any) {
        guard let item = selectedMessage else {
            return
        }
        print(item.content)
    }
    
    @objc func deleteAction(_ sender: Any) {
        guard let item = selectedMessage else {
            return
        }
        print(item.content)
    }
}

extension ChatViewController: UITextViewDelegate {
    
    func prepareTextView() {
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1 / UIScreen.main.scale
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = textViewHeightConstraint.constant / 2
        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.textContainerInset = UIEdgeInsetsMake(7, 8, 7, 8)
    }
    
    func clearTextView() {
        textView.text = ""
        updateTextViewHeight(height: 34.0, animated: false)
        rightButton.isHidden = false
        sendButton.isHidden = true
    }
    
    func updateTextViewHeight(height: CGFloat , animated: Bool) {
        let dvalue = height - textViewHeightConstraint.constant
        textViewHeightConstraint.constant = height
        heightConstraint.constant = height + 15.0
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentOffset.y + dvalue)
                self.currentContentOffsetY = self.currentContentOffsetY + dvalue
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let lineHeight = textView.font?.lineHeight else {
            return
        }
        
        let maxRow = 6
        let maxHeight = ceilf(Float(lineHeight * CGFloat(maxRow) + textView.textContainerInset.top + textView.textContainerInset.bottom))
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat(MAXFLOAT)))
        let height = ceilf(Float(size.height))
        let currentHeight = ceilf(Float(textView.bounds.height))
        textView.isScrollEnabled = height > maxHeight && maxHeight > 0
        let targetHeight = textView.isScrollEnabled ? maxHeight : height
        if currentHeight != targetHeight {
            updateTextViewHeight(height: CGFloat(targetHeight), animated: true)
        }
        if textView.text.count == 0 {
            rightButton.isHidden = false
            sendButton.isHidden = true
        } else {
            rightButton.isHidden = true
            sendButton.isHidden = false
        }
    }
}

extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate , TZImagePickerControllerDelegate {
    
    func sendPhoto(_ image: UIImage) {
        guard let account = AccountAPI.shared.account else {
            return
        }
        guard let conversationId = self.conversationId else {
            return
        }
        guard let data = image.getData() else {
            return
        }
        
        DispatchQueue.global().async {
            let path = NSTemporaryDirectory()
            let url = URL(fileURLWithPath: "\(path)\(conversationId)_photorandom_id_\(image.hashValue)")
            try? data.write(to: url)
            
            var message = MessageItem(messageId: UUID().uuidString, conversationId: conversationId, content: "photo")
            message.userId = account.id
            message.userFullName = account.full_name
            message.userIdentityNumber = account.identity_number
            message.type = .photo
            message.mediaUrl = url.absoluteString
            message.mediaMineType = "png"
            message.mediaWidth = Int(image.size.width)
            message.mediaHeight = Int(image.size.height)
            message.mediaSize = data.count
            MessageDAO.shared.sendMessage(message: message)
        }
    }
    
    func sendGif(_ data: Data, size: CGSize) {
        guard let account = AccountAPI.shared.account else {
            return
        }
        guard let conversationId = self.conversationId else {
            return
        }
        
        DispatchQueue.global().async {
            let path = NSTemporaryDirectory()
            let url = URL(fileURLWithPath: "\(path)\(conversationId)_photorandom_id_\(data.hashValue)")
            try? data.write(to: url)
            
            var message = MessageItem(messageId: UUID().uuidString, conversationId: conversationId, content: "photo")
            message.userId = account.id
            message.userFullName = account.full_name
            message.userIdentityNumber = account.identity_number
            message.type = .photo
            message.mediaUrl = url.absoluteString
            message.mediaMineType = "gif"
            message.mediaWidth = Int(size.width)
            message.mediaHeight = Int(size.height)
            message.mediaSize = data.count
            MessageDAO.shared.sendMessage(message: message)
        }
    }
    
    func sendVideo(_ coverImage: UIImage, data: Data) {
        
        
    }
    
    func openCamera(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerControllerSourceType.camera
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func openAlbum(){
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }

        if let picker = TZImagePickerController.init(maxImagesCount: 9, columnNumber: 4, delegate: self) {
            picker.allowPickingGif = true
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            sendPhoto(image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool, infos: [[AnyHashable : Any]]!) {
        guard photos.count > 0 else {
            return
        }
        
        for image in photos {
            sendPhoto(image)
        }
    }
    
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingGifImage animatedImage: UIImage!, sourceAssets asset: Any!) {
        guard let manager = TZImageManager.default() else {
            return
        }
        
        manager.getOriginalPhotoData(withAsset: asset, completion: { (imageData, info, isDegraded) in
            guard let data = imageData else {
                return
            }
            self.sendGif(data, size: CGSize.init(width: animatedImage.size.width, height: animatedImage.size.height))
        })
        
    }
    
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingVideo coverImage: UIImage!, sourceAssets asset: Any!) {
        
    }
}

extension ChatViewController {

    @objc func keyboardWillChangeFrame(_ sender: Notification) {
        guard let info = sender.userInfo else {
            return
        }
        guard let duration = (info[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
            return
        }
        guard let beginKeyboardRect = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        guard let endKeyboardRect = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        guard isDidAppear else {
            return
        }
        
        UIView.animate(withDuration: duration, animations: {
            self.showOrHideKeyboard(beginKeyboardRect, endKeyboardRect)
        })
    }
    
    func showOrHideKeyboard(_ beginKeyboardRect: CGRect, _ endKeyboardRect: CGRect) {
        let bounds = UIScreen.main.bounds
        
        if endKeyboardRect.origin.y == bounds.height || endKeyboardRect.origin.y == bounds.width {
            bottomConstraint.constant = 0
            isShowedKeyboard = false
            let tableViewHeight = view.bounds.height - beginKeyboardRect.height - textViewHeightConstraint.constant
            if (tableView.contentSize.height > tableViewHeight) {
                if (tableView.contentSize.height < tableViewHeight) {
                    tableView.contentOffset = CGPoint.zero
                } else {
                    tableView.contentOffset = CGPoint(x: 0, y: currentContentOffsetY - beginKeyboardRect.height)
                }
            }
        } else {
            if #available(iOS 11.0, *) {
                bottomConstraint.constant = -endKeyboardRect.height + view.safeAreaInsets.bottom
            } else {
                bottomConstraint.constant = -endKeyboardRect.height
            }
            if !isShowedKeyboard {
                currentContentOffsetY = tableView.contentOffset.y
                isShowedKeyboard = true
            }
            let tableViewHeight = view.bounds.height - endKeyboardRect.height - textViewHeightConstraint.constant
            if (tableView.contentSize.height > tableViewHeight) {
                if (tableView.contentSize.height < tableViewHeight) {
                    tableView.contentOffset = CGPoint.zero
                } else {
                    tableView.contentOffset = CGPoint(x: 0, y: currentContentOffsetY + endKeyboardRect.height)
                }
            }
            UIMenuController.shared.menuItems = nil
        }
        self.view.layoutIfNeeded()
    }

}
