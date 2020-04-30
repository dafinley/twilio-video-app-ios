//
//  Copyright (C) 2020 Twilio, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import MessageKit
import InputBarAccessoryView
import Starscream
import SwiftyJSON


@available(iOS 12.0, *)
@objc class ChatViewController : MessagesViewController, WebSocketDelegate {
    var messages: [Message] = []
    var roomSender: MessageSender!
    var userSender: MessageSender!
    @objc var roomName: String = ""
    let refreshControl = UIRefreshControl()
    var socketService: WebSocketService!
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    
    override func viewDidLoad() {
      super.viewDidLoad()
        roomSender = MessageSender(senderId: UUID().uuidString, name: "")
        userSender = MessageSender(senderId: SwiftToObjc.userId, name: SwiftToObjc.userDisplayName)
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.addSubview(refreshControl)
        socketService = WebSocketService(wsd: self)
    
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
          layout.setMessageIncomingAvatarSize(.zero)
          layout.setMessageOutgoingAvatarSize(.zero)
        }
        
    }
    
    
    
    
    func insertMessage(_ message: Message) {
        
        messages.append(message)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)

    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !messages.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    override func viewDidDisappear(_ animated: Bool){
        super.viewDidDisappear(animated)
        socketService.disconnect()
    }
    
    override func viewDidAppear(_ animated: Bool){
        super.viewDidAppear(animated)
        let m = Message(sender: roomSender,
        text: "Welcome " + SwiftToObjc.userDisplayName + ", You have joined " + roomName,
        messageId: UUID().uuidString)
        socketService.writePOST(msg: m)
        
    }
    
    // MARK: - WebSocketDelegate
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            socketService.isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            socketService.isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string as Any):
            
            let json = string as? String
            print(string)
            if let dataFromString = json!.data(using: .utf8, allowLossyConversion: false) {
                do {
                    let j: JSON =  try! JSON(data: dataFromString)
                    
                    let m: Message = Message(fromJSON: (j.dictionaryObject!))!
                    insertMessage(m)
                }
            }
            
            
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            socketService.isConnected = false
        case .error(let error):
            socketService.isConnected = false
            socketService.handleError(error)
        }
    }
    
}

@available(iOS 12.0, *)
extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return userSender
    }
    
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section % 3 == 0 {
          return 30
        }
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView:
        MessagesCollectionView) -> CGFloat {
        if message.sender.displayName == "" || message.sender.senderId == currentSender().senderId {
            return 0
        }
      return 30
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
    
    
    
    func messageLabelInset(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        
        return UIEdgeInsets()
    }
    
}

@available(iOS 12.0, *)
extension ChatViewController: InputBarAccessoryViewDelegate {
  func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
      let components = inputBar.inputTextView.components
      messageInputBar.inputTextView.text = String()
      messageInputBar.invalidatePlugins()
      // Send button activity animation
      messageInputBar.sendButton.startAnimating()
      messageInputBar.inputTextView.placeholder = "Sending..."
      DispatchQueue.global(qos: .default).async {
          // fake send request task
          sleep(1)
          DispatchQueue.main.async { [weak self] in
              self?.messageInputBar.sendButton.stopAnimating()
              self?.messageInputBar.inputTextView.placeholder = "Aa"
              self?.insertMyMessages(components)
              self?.messagesCollectionView.scrollToBottom(animated: true)
          }
      }
    }
    
  private func insertMyMessages(_ data: [Any]) {
      for component in data {
          if let str = component as? String {
            
            let message = Message(sender: userSender, text: str, messageId: UUID().uuidString)
            socketService.writePOST(msg: message)
          }
      }
  }
}

@available(iOS 12.0, *)
extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
      avatarView.isHidden = true
    }
}

