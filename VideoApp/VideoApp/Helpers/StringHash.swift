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
import CommonCrypto

public extension String {
  
  var md5: String {
    
    let length = Int(CC_MD5_DIGEST_LENGTH)
    
    guard let data = data(using: .utf8) else {
      return self
    }
    
    let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
      var hash = [UInt8](repeating: 0, count: length)
        CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
      return hash
    }
    
    return (0..<length)
      .map { String(format: hashFormat, hash[$0]) }
      .joined()
  }
  
  
  /// hashFormat - %02x
  private var hashFormat: String {
    return  "%02x"
  }
  
}
