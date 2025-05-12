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
      DDLogDebug(message, tag: tag)
    case .error:
      DDLogError(message, tag: tag)
    case .info:
      DDLogInfo(message, tag: tag)
    case .verbose:
      DDLogVerbose(message, tag: tag)
    case .warning:
      DDLogWarn(message, tag: tag)
    default:
      DDLogInfo(message, tag: tag)
    }
  }
}
