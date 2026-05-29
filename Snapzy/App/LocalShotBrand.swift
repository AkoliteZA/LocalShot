//
//  LocalShotBrand.swift
//  Snapzy
//
//  LocalShot v1 identity and feature policy.
//

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
    let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
    return (pictures ?? FileManager.default.homeDirectoryForCurrentUser)
      .appendingPathComponent(exportDirectoryName, isDirectory: true)
  }

  static var applicationSupportDirectory: URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
      .appendingPathComponent(applicationSupportDirectoryName, isDirectory: true)
  }
}

enum LocalShotV1Policy {
  static let cloudUploadsEnabled = false
  static let updaterEnabled = false
  static let diagnosticsEnabledByDefault = false
  static let problemReportsEnabled = false
  static let complexVideoEditorEntryPointsEnabled = false

  static func shareableCloudURL(_ url: URL?) -> URL? {
    guard cloudUploadsEnabled else { return nil }
    return url
  }
}
