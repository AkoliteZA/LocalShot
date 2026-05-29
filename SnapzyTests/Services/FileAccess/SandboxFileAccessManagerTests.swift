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
}
