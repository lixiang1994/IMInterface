import Foundation
import UIKit

extension NSNotification.Name {

    static let SocketConnecting = NSNotification.Name("lee.im.ios.websocket.connecting")
    static let SocketConnected = NSNotification.Name("lee.im.ios.websocket.connected")
    static let SocketDisconnected = NSNotification.Name("lee.im.ios.websocket.disconnected")

    static let MessageDidChange = NSNotification.Name("lee.im.ios.sqlite.messages.changed")
}

struct Storyboard {
    static let chat = UIStoryboard(name: "Chat", bundle: Bundle.main)
}
