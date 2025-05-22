// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftyJSON
import Foundation
import PDLogger

private class SettingsFetcher {
  nonisolated(unsafe) static let instance = SettingsFetcher()
  static func storeURL() -> URL? {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }
    let directory = documentsDirectory.appendingPathComponent("settings")
    
    do {
      if !FileManager.default.fileExists(atPath: directory.path) {
        try FileManager.default.createDirectory(atPath: directory.path, withIntermediateDirectories: true)
      }
    } catch {
      print("Error encoding or writing JSON: \(error)")
      return nil
    }
    
    return directory.appendingPathComponent("settings.json")
  }
  
  private static var bundle: Bundle {
    return Bundle.module
  }
  
  private var json: JSON? {
    var storedJson: JSON?
    if let stored = Self.storeURL(), FileManager.default.fileExists(atPath: stored.path) {
      do {
        let data = try Data(contentsOf: stored)
        let json = try JSON(data: data)
        logger.log("SettingsFetcher", .info, message: "parse stored settings json success, json: \(json)")
        storedJson = json
      } catch {
        logger.log("SettingsFetcher", .error, message: "parse stored settings json fail, error: \(error)")
      }
    }
    
    guard let url = Self.bundle.url(forResource: "settings", withExtension: "json") else {
      logger.log("SettingsFetcher", .error, message: "get preset settings failed")
      return storedJson
    }
    
    do {
      let data = try Data(contentsOf: url)
      let json = try JSON(data: data)
      logger.log("SettingsFetcher", .info, message: "parse preset settings success, json: \(json)")
      
      if let storedJson,
         let storedVersionStr = storedJson["version"].string, let storedVersion = SettingsVersion(string: storedVersionStr),
         let presetVersionStr = json["version"].string, let presetVersion = SettingsVersion(string: presetVersionStr),
         presetVersionStr <= storedVersionStr {
        logger.log("SettingsFetcher", .info, message: "stored settings pass version check, storedVersion: \(storedVersion), presetVersion: \(presetVersion)")
        return storedJson
      } else {
        return json
      }
    } catch {
      logger.log("SettingsFetcher", .error, message: "parse preset settings fail, error: \(error)")
      return nil
    }
  }
  
  private static let remote =
  logger.DEBUG ? "https://gitee.com/waichen/pdviewer-settings/raw/develop/Sources/pdviewer-settings/Resources/settings.json" : "https://gitee.com/waichen/pdviewer-settings/raw/release/Sources/pdviewer-settings/Resources/settings.json"
  
  private static let remoteURL: URL? = URL(string: remote)
  
  func async() -> JSON? {
    defer {
      logger.log("SettingsFetcher", .info, message: "will download file from: \(Self.remoteURL) to: \(Self.storeURL())")
      
      if let remoteURL = Self.remoteURL, let url = Self.storeURL() {
        logger.log("SettingsFetcher", .info, message: "begin download file from: \(remoteURL) to: \(url)")
        
        downloadFile(from: remoteURL, to: url) { result in
          logger.log("SettingsFetcher", .info, message: "download result: \(result)")
        }
      }
    }
    
    return json
  }
  
  private func downloadFile(from url: URL, to destinationURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
    let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
      DispatchQueue.main.async {
        do {
          if let error = error {
            completion(.failure(error))
            return
          }
          
          guard let tempURL = tempURL else {
            completion(.failure(NSError(domain: "DownloadError", code: -1, userInfo: nil)))
            return
          }
          
          let data = try Data(contentsOf: tempURL)
          let json = try JSON(data: data)
          logger.log("SettingsFetcher", .info, message: "Parse Json Successfully: \(json)")
          
          guard let versionStr = json["version"].string, let version = SettingsVersion(string: versionStr) else {
            completion(.failure(NSError(domain: "ParseJsonError", code: -3, userInfo: nil)))
            return
          }
          
          logger.log("SettingsFetcher", .info, message: "new settings version: \(version)")
          
          guard let minAppVersionStr = json["min_supported_app_version"].string, let minAppVersion = SettingsVersion(string: minAppVersionStr) else {
            completion(.failure(NSError(domain: "ParseJsonError", code: -4, userInfo: nil)))
            return
          }
          
          logger.log("SettingsFetcher", .info, message: "Min App Version Required: \(minAppVersion)")
          
          guard let appVersionStr = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let appVersion = SettingsVersion(string: appVersionStr) else {
            completion(.failure(NSError(domain: "ParseAppVersionError", code: -5, userInfo: nil)))
            return
          }
          
          logger.log("SettingsFetcher", .info, message: "App Version: \(appVersion)")
          
          guard appVersion >= minAppVersion else {
            completion(.failure(NSError(domain: "MinAppVersionCheckError", code: -6, userInfo: nil)))
            return
          }
          
          // 删除已有文件（如果存在）
          if FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
              let oData = try Data(contentsOf: destinationURL)
              let oJson = try JSON(data: oData)
              if let oVersionStr = oJson["version"].string,
                 let oVersion = SettingsVersion(string: oVersionStr) {
                logger.log("SettingsFetcher", .info, message: "old settings version: \(oVersion)")
                if logger.DEBUG {
                  // DEBUG环境下，settings文件的version弱检查，因为不可能频繁更新version字段
                  if oVersion > version {
                    completion(.failure(NSError(domain: "VersionCoverError", code: -7, userInfo: nil)))
                    return
                  }
                } else {
                  if oVersion >= version {
                    completion(.failure(NSError(domain: "VersionCoverError", code: -8, userInfo: nil)))
                    return
                  }
                }
              }
            } catch {
              logger.log("SettingsFetcher", .warning, message: "handle stored json fail, error: \(error)")
            }
            
            try? FileManager.default.removeItem(at: destinationURL)
          }
          // 移动下载的文件到目标位置
          try FileManager.default.moveItem(at: tempURL, to: destinationURL)
          completion(.success(destinationURL))
        } catch {
          completion(.failure(error))
        }
      }
    }
    
    task.resume()
  }
}

@available(iOS 13.0, macOS 10.15, *)
public final class Settings: @unchecked Sendable {
  // 使用静态常量实现线程安全的单例
  public static let instance: Settings = {
    let instance = Settings()
    logger.log("Settings", .info, message: "init with new instance: \(instance)")
    return instance
  }()
  
  private init() {
    self.json = SettingsFetcher.instance.async()
    
    logger.log("Settings", .info, message: "did init, json: \(json)")
  }
  
  private let json: JSON?
  
  public func setup() {
    logger.log("Settings", .info, message: "setup")
  }
  
  public private(set) lazy var tutorials: [Tutorial] = {
    json?["tutorials"].arrayValue.map({ Tutorial(json: $0) }) ?? []
  }()
  
  public private(set) lazy var forceSplitMultiTexture: Bool = {
    json?["force_split_multi_texture"].bool ?? true
  }()
  
  public private(set) lazy var forcePreviewMultiTexture: Bool = {
    json?["force_preview_multi_texture"].bool ?? true
  }()
  
  public private(set) lazy var forceDrawMultiTexture: Bool = {
    json?["force_draw_multi_textrue"].bool ?? true
  }()
  
  public private(set) lazy var downSampleIfNeeded: Bool = {
    json?["downsample_if_needed"].bool ?? false
  }()
  
  public private(set) lazy var contactDeveloperTutorial: Tutorial? = {
    tutorials.first(where: { $0.identifier == "contact_developer" })
  }()
}
