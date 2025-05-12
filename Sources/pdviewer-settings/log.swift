//
//  log.swift
//  pixelanim-settings
//
//  Created by Yachong Chen on 2025/5/10.
//

import CocoaLumberjackSwift

func log(_ tag: String, _ flag: DDLogFlag, message: String) {
  DispatchQueue.main.async {
    if SettingsInjection.instance.debug {
      print("ℹ️ [\(tag)] \(message)")
    } else if SettingsInjection.instance.loggingEnable {
      NSLog("ℹ️ [\(tag)] \(message)")
    }
    
    switch flag {
    case .debug:
      DDLogDebug("🐞 [\(tag)] \(message)", tag: tag)
    case .error:
      DDLogError("❌ [\(tag)] \(message)", tag: tag)
    case .info:
      DDLogInfo("📘 [\(tag)] \(message)", tag: tag)
    case .verbose:
      DDLogVerbose("🔍 [\(tag)] \(message)", tag: tag)
    case .warning:
      DDLogWarn("⚠️ [\(tag)] \(message)", tag: tag)
    default:
      DDLogInfo("📘 [\(tag)] \(message)", tag: tag)
    }
  }
}
