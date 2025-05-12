//
//  SettingsVersion.swift
//  pixelanim-settings
//
//  Created by Yachong Chen on 2025/5/10.
//

import Foundation

/// 自定义版本号类，支持语义化版本比较
struct SettingsVersion: Comparable, CustomStringConvertible {
    // MARK: - 属性
    let major: Int
    let minor: Int
    let patch: Int
    let prerelease: String?  // 预发布标识（如 "beta", "alpha.1"）
    let buildMetadata: String? // 构建元数据（如 "exp.sha.5114f85"）
    
    // 格式化为字符串
    var description: String {
        var base = "\(major).\(minor).\(patch)"
        if let prerelease = prerelease { base += "-\(prerelease)" }
        if let buildMetadata = buildMetadata { base += "+\(buildMetadata)" }
        return base
    }
    
    // MARK: - 初始化
    init(major: Int, minor: Int = 0, patch: Int = 0, prerelease: String? = nil, buildMetadata: String? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.buildMetadata = buildMetadata
    }
    
    /// 从字符串解析版本号（如 "1.2.3-alpha+exp"）
    init?(string: String) {
        // 正则表达式匹配语义化版本（SemVer 2.0）
        let pattern = #"^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+([0-9A-Za-z.-]+))?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else {
            return nil
        }
        
        // 提取主版本号
        guard let majorRange = Range(match.range(at: 1), in: string),
              let major = Int(String(string[majorRange])) else {
            return nil
        }
        
        // 提取次版本号（可选）
        let minor = match.range(at: 2).location != NSNotFound ?
            Int(String(string[Range(match.range(at: 2), in: string)!])) ?? 0 : 0
        
        // 提取修订号（可选）
        let patch = match.range(at: 3).location != NSNotFound ?
            Int(String(string[Range(match.range(at: 3), in: string)!])) ?? 0 : 0
        
        // 提取预发布标识（可选）
        let prerelease = match.range(at: 4).location != NSNotFound ?
            String(string[Range(match.range(at: 4), in: string)!]) : nil
        
        // 提取构建元数据（可选）
        let buildMetadata = match.range(at: 5).location != NSNotFound ?
            String(string[Range(match.range(at: 5), in: string)!]) : nil
        
        self.init(major: major, minor: minor, patch: patch, prerelease: prerelease, buildMetadata: buildMetadata)
    }
    
    // MARK: - 比较逻辑
    static func == (lhs: SettingsVersion, rhs: SettingsVersion) -> Bool {
        return lhs.major == rhs.major &&
               lhs.minor == rhs.minor &&
               lhs.patch == rhs.patch &&
               lhs.prerelease == rhs.prerelease // 注意：构建元数据不参与比较
    }
    
    static func < (lhs: SettingsVersion, rhs: SettingsVersion) -> Bool {
        // 比较主版本号
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        
        // 预发布版本 < 正式版本（如 1.0.0-alpha < 1.0.0）
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil): return false // 两者均为正式版
        case (nil, _):   return false // lhs是正式版，rhs是预发布版 => lhs > rhs
        case (_, nil):   return true  // lhs是预发布版，rhs是正式版 => lhs < rhs
        case (let a?, let b?): return a < b // 两者均为预发布版，按字符串比较
        }
    }
}
