//
//  Tutorial.swift
//  pixelanim-settings
//
//  Created by Yachong on 2025/5/8.
//

import UIKit
import SwiftyJSON
import DeviceKit

public enum TutorialType: Int, Codable {
  case normal
  case pro
  case special
}

public struct Tutorial: Decodable {
  public let title: String
  public let description: String
  public let type: TutorialType
  public let identifier: String?
  let baseURL: String
  let iPadURL: String?
  
  init(json: JSON) {
    title = json["title"].stringValue
    description = json["description"].stringValue
    baseURL = json["base_url"].stringValue
    iPadURL = json["ipad_url"].string
    type = TutorialType(rawValue: json["type"].intValue) ?? .normal
    identifier = json["identifier"].string
  }
  
  public var url: String {
    if let iPadURL, Device.current.isPad {
      iPadURL
    } else {
      baseURL
    }
  }
}

