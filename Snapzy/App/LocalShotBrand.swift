//
//  LocalShotBrand.swift
//  Snapzy
//
//  LocalShot v1 identity and feature policy.
//

import Darwin
import Foundation

enum LocalShotBrand {
  static let appName = "LocalShot"
  static let bundleIdentifier = "com.personal.localshot"
  static let urlScheme = "localshot"
  static let applicationSupportDirectoryName = "LocalShot"
  static let exportDirectoryName = "LocalShot"
  static let diagnosticsDirectoryName = "LocalShot"
  static let diagnosticsFilePrefix = "localshot_"
  static let queueLabelPrefix = "com.personal.localshot"
  static let configurationDirectoryName = "localshot"
  static let databaseFileName = "localshot.db"

  static var defaultExportDirectory: URL {
    userHomeDirectory
      .appendingPathComponent("Pictures", isDirectory: true)
      .appendingPathComponent(exportDirectoryName, isDirectory: true)
  }

  static var applicationSupportDirectory: URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
      .appendingPathComponent(applicationSupportDirectoryName, isDirectory: true)
  }

  private static var userHomeDirectory: URL {
    guard
      let passwd = getpwuid(getuid()),
      let home = passwd.pointee.pw_dir
    else {
      return FileManager.default.homeDirectoryForCurrentUser
    }

    let path = String(cString: home)
    guard !path.isEmpty else {
      return FileManager.default.homeDirectoryForCurrentUser
    }
    return URL(fileURLWithPath: path, isDirectory: true)
  }
}

enum LocalShotV1Policy {
  static let cloudUploadsEnabled = false
  static let updaterEnabled = false
  static let diagnosticsEnabledByDefault = false
  static let diagnosticsPreferencesVisible = false
  static let problemReportsEnabled = false
  static let complexVideoEditorEntryPointsEnabled = false
  static let sponsorPromptsEnabled = false

  static func shareableCloudURL(_ url: URL?) -> URL? {
    guard cloudUploadsEnabled else { return nil }
    return url
  }
}
