//
//  MenuSaveLocationFormatter.swift
//  Snapzy
//
//  Formats the menu bar save-location footer.
//

import Foundation

enum MenuSaveLocationFormatter {
  static func title(
    for path: String,
    homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
    defaultPath: String = LocalShotBrand.defaultExportDirectory.path
  ) -> String {
    "Saving to \(displayPath(for: path, homeDirectory: homeDirectory, defaultPath: defaultPath))"
  }

  private static func displayPath(
    for path: String,
    homeDirectory: URL,
    defaultPath: String
  ) -> String {
    let rawPath = path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultPath : path
    let expandedPath = (rawPath as NSString).expandingTildeInPath
    let normalizedPath = URL(fileURLWithPath: expandedPath).standardizedFileURL.path
    let homePath = homeDirectory.standardizedFileURL.path

    if normalizedPath == homePath {
      return "~"
    }

    guard homePath != "/", normalizedPath.hasPrefix(homePath + "/") else {
      return normalizedPath
    }

    return "~" + normalizedPath.dropFirst(homePath.count)
  }
}
