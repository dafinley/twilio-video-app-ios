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

struct Member {
  let id: String
  let name: String
}

extension Member {
  var toJSON: Any {
    return [
        "id": id,
      "name": name
    ]
  }
  
  init?(fromJSON json: Any) {
    guard
      let data = json as? [String: Any],
      let name = data["name"] as? String,
      let id = data["id"] as? String
      else {
        print("Couldn't parse Member")
        return nil
    }
    
    self.name = name
    self.id = id
  }
}

extension UIColor {
  static var random: UIColor {
    return UIColor(
      red: CGFloat.random(in: 0...1),
      green: CGFloat.random(in: 0...1),
      blue: CGFloat.random(in: 0...1),
      alpha: 1)
  }
}

extension UIColor {
  convenience init(hex: String) {
    var hex = hex
    if hex.hasPrefix("#") {
      hex.remove(at: hex.startIndex)
    }
    
    var rgb: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&rgb)
    
    let r = (rgb & 0xff0000) >> 16
    let g = (rgb & 0xff00) >> 8
    let b = rgb & 0xff
    
    self.init(
      red: CGFloat(r) / 0xff,
      green: CGFloat(g) / 0xff,
      blue: CGFloat(b) / 0xff, alpha: 1
    )
  }
  
  var hexString: String {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    
    self.getRed(&r, green: &g, blue: &b, alpha: &a)
    
    return String(
      format: "#%02X%02X%02X",
      Int(r * 0xff),
      Int(g * 0xff),
      Int(b * 0xff)
    )
  }
}
