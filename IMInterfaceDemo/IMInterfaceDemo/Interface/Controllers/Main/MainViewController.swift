import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private let cellIdentifier = "cell_identifier_conversation"
    
    private lazy var conversations = ConversationDAO.shared.conversationList()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareTableView()
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    private func prepareTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "ConversationCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView.separatorStyle = .singleLine
        tableView.tableFooterView = UIView()
        NotificationCenter.default.addObserver(self, selector: #selector(messageDidChange(_:)), name: NSNotification.Name.MessageDidChange, object: nil)
    }
    
    @objc func messageDidChange(_ sender: Notification) {
        guard tableView != nil else {
            return
        }
        conversations = ConversationDAO.shared.conversationList()
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ConversationCell
        cell.render(item: conversations[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message: ConversationItem = conversations[indexPath.row]
        navigationController?.pushViewController(ChatViewController.instance(conversation: message), animated: true)
    }
}
