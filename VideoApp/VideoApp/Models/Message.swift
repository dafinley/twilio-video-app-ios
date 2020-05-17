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
import UIKit
import MessageKit


struct Message {
  let sender: SenderType
  let text: String
  let messageId: String
  let created: Date
  let room: String
}

extension Message: MessageType {
    
    var toJSON: [String: Any] {
      return [
          "id": messageId,
        "text": text,
        "senderId": sender.senderId,
        "name": sender.displayName,
        "created": created.millisecondsSince1970,
        "room": room
      ]
    }
    
    init?(fromJSON data: [String: Any?]) {
      guard
        let text = data["text"] as? String,
        let id = data["id"] as? String,
        let senderId = data["senderId"] as? String,
        let name: String = data["name"] as? String,
        let room: String = data["room"] as? String,
        let created: Int64 = data["created"] as? Int64
        else {
          print("Couldn't parse Message")
          return nil
      }

        self.sender = MessageSender(senderId: senderId, name: name)
        self.text = text
        self.messageId = id
        self.created = Date(milliseconds: created)
        self.room = room
    }
  
  var sentDate: Date {
    return created
  }
  
  var kind: MessageKind {
    return .attributedText(NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)]))
  }
    
}
