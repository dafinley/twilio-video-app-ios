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
import Starscream
import Alamofire

@available(iOS 12.0, *)
class WebSocketService {
    
    var socketURL: URLRequest!
    let socket: WebSocket!
    var isConnected = false
    
    public init(wsd: WebSocketDelegate){
        socketURL = URLRequest(url: URL(string: "wss://chat.starlineventures.com/subscribe")!)

        socketURL.timeoutInterval = 5
        socket = WebSocket(request: socketURL)
        socket.delegate = wsd;
        socket.connect()
        
    }
    
    // MARK: Write Text Action
    
    func sampleText(str: String){
        socket.write(string: str)
    }
    
    func writePOST(msg: Message?){
        let params: Parameters = msg!.toJSON
        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        AF.request("https://chat.starlineventures.com/publish",
                   method: .post,
                   parameters: params,
                   encoding: JSONEncoding.prettyPrinted,
                   headers: headers)
            .responseJSON{_ in }
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }
}


