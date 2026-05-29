//
//  SandboxFileAccessManagerTests.swift
//  SnapzyTests
//
//  Regression coverage for local save-folder permission checks.
//

import Foundation
import XCTest
@testable import LocalShot

@MainActor
final class SandboxFileAccessManagerTests: XCTestCase {
  func testWritableExportDirectoryDoesNotRequireSecurityScopePrompt() throws {
    let defaults = UserDefaultsFactory.make()
    let exportDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: exportDirectory) }

    defaults.set(exportDirectory.path, forKey: PreferencesKeys.exportLocation)

    let manager = SandboxFileAccessManager(
      defaults: defaults,
      defaultExportDirectoryProvider: { exportDirectory },
      securityScopeAccessProvider: { _ in false }
    )

    XCTAssertTrue(manager.hasPersistedExportPermission)
  }

  func testSetExportDirectoryCreatesBookmarkFromSelectedURLBeforeNormalizingStoredPath() throws {
    let defaults = UserDefaultsFactory.make()
    let selectedDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
      .appendingPathComponent("..", isDirectory: true)
      .appendingPathComponent("Chosen", isDirectory: true)
    let normalizedDirectory = selectedDirectory.standardizedFileURL
    try FileManager.default.createDirectory(at: normalizedDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: normalizedDirectory) }

    var bookmarkSourceURL: URL?
    let manager = SandboxFileAccessManager(
      defaults: defaults,
      defaultExportDirectoryProvider: { normalizedDirectory },
      securityScopedBookmarkDataProvider: { url in
        bookmarkSourceURL = url
        return Data([0x4c, 0x53])
      }
    )

    XCTAssertTrue(manager.setExportDirectory(selectedDirectory))
    XCTAssertEqual(bookmarkSourceURL, selectedDirectory)
    XCTAssertEqual(defaults.string(forKey: PreferencesKeys.exportLocation), normalizedDirectory.path)
    XCTAssertEqual(defaults.data(forKey: PreferencesKeys.exportLocationBookmark), Data([0x4c, 0x53]))
  }
}
