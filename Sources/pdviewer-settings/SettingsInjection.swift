//
//  SettingsInjection.swift
//  pixelanim-settings
//
//  Created by Yachong Chen on 2025/5/10.
//

import Foundation

public protocol SettingsInjectable: AnyObject {
  func debug() -> Bool
  func loggingEnable() -> Bool
}

@available(iOS 13.0, macOS 10.15, *)
public final class SettingsInjection: @unchecked Sendable {
  // 使用静态常量实现线程安全的单例
  public static let instance: SettingsInjection = {
    let instance = SettingsInjection()
    log("SettingsInjection", .info, message: "init with new instance: \(instance)")
    return instance
  }()
  
  private weak var injectable: SettingsInjectable?
  
  public func inject(_ obj: SettingsInjectable) {
    injectable = obj
  }
  
  var debug: Bool { injectable?.debug() ?? false }
  var loggingEnable: Bool { injectable?.loggingEnable() ?? false }
}
