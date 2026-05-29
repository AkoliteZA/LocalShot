//
//  SnapzyConfigurationImporterTests.swift
//  SnapzyTests
//
//  Unit tests for TOML configuration import validation and application.
//

import XCTest
@testable import LocalShot

@MainActor
final class SnapzyConfigurationImporterTests: XCTestCase {
  func testImportAppliesCaptureAndRecordingSettingsToProvidedDefaults() {
    let defaults = UserDefaultsFactory.make()
    let source = """
    schema_version = 1

    [capture.screenshot]
    format = "webp"
    show_cursor = true

    [recording]
    fps = 60
    """

    let result = SnapzyConfigurationImporter.importTOML(source, defaults: defaults)

    XCTAssertFalse(result.hasErrors)
    XCTAssertGreaterThanOrEqual(result.appliedChangeCount, 3)
    XCTAssertEqual(defaults.string(forKey: PreferencesKeys.screenshotFormat), "webp")
    XCTAssertEqual(defaults.object(forKey: PreferencesKeys.screenshotShowCursor) as? Bool, true)
    XCTAssertEqual(defaults.object(forKey: PreferencesKeys.recordingFPS) as? Int, 60)
  }

  func testImportRejectsUnsupportedSchemaBeforeMutatingDefaults() {
    let defaults = UserDefaultsFactory.make()
    defaults.set("png", forKey: PreferencesKeys.screenshotFormat)
    let source = """
    schema_version = 99

    [capture.screenshot]
    format = "webp"
    """

    let result = SnapzyConfigurationImporter.importTOML(source, defaults: defaults)

    XCTAssertTrue(result.hasErrors)
    XCTAssertEqual(result.appliedChangeCount, 0)
    XCTAssertEqual(defaults.string(forKey: PreferencesKeys.screenshotFormat), "png")
  }

  func testImportRejectsInvalidEnumsBeforeApplyingAnyMutation() {
    let defaults = UserDefaultsFactory.make()
    defaults.set("png", forKey: PreferencesKeys.screenshotFormat)
    let source = """
    schema_version = 1

    [capture.screenshot]
    format = "bmp"
    show_cursor = true
    """

    let result = SnapzyConfigurationImporter.importTOML(source, defaults: defaults)

    XCTAssertTrue(result.hasErrors)
    XCTAssertEqual(result.appliedChangeCount, 0)
    XCTAssertEqual(defaults.string(forKey: PreferencesKeys.screenshotFormat), "png")
    XCTAssertNil(defaults.object(forKey: PreferencesKeys.screenshotShowCursor))
  }

  func testImportRejectsUnknownShortcutModifiers() {
    let defaults = UserDefaultsFactory.make()
    let source = """
    schema_version = 1

    [shortcuts.global.fullscreen]
    key = "3"
    modifiers = ["command", "hyper"]
    """

    let result = SnapzyConfigurationImporter.importTOML(source, defaults: defaults)

    XCTAssertTrue(result.hasErrors)
    XCTAssertEqual(result.appliedChangeCount, 0)
  }

  func testImportExpandsTildePathsAgainstUserHomeDirectory() {
    let defaults = UserDefaultsFactory.make()
    let source = """
    schema_version = 1

    [general]
    export_location = "~/Desktop"
    """

    let result = SnapzyConfigurationImporter.importTOML(source, defaults: defaults)

    XCTAssertFalse(result.hasErrors)
    XCTAssertTrue(result.issues.isEmpty)
    XCTAssertEqual(
      defaults.string(forKey: PreferencesKeys.exportLocation),
      SnapzyConfigurationPaths.expandedUserPath("~/Desktop")
    )
  }

  func testImportDoesNotEnableDiagnosticsForLocalShotV1() {
    let defaults = UserDefaultsFactory.make()
    defaults.set(false, forKey: PreferencesKeys.diagnosticsEnabled)
    let source = """
    schema_version = 1

    [diagnostics]
    enabled = true
    """

    let result = SnapzyConfigurationImporter.importTOML(source, defaults: defaults)

    XCTAssertFalse(result.hasErrors)
    XCTAssertEqual(defaults.object(forKey: PreferencesKeys.diagnosticsEnabled) as? Bool, false)
  }

  func testImportDisablesExistingDiagnosticsForLocalShotV1() {
    let defaults = UserDefaultsFactory.make()
    defaults.set(true, forKey: PreferencesKeys.diagnosticsEnabled)
    let source = """
    schema_version = 1

    [diagnostics]
    enabled = true
    """

    let result = SnapzyConfigurationImporter.importTOML(source, defaults: defaults)

    XCTAssertFalse(result.hasErrors)
    XCTAssertEqual(defaults.object(forKey: PreferencesKeys.diagnosticsEnabled) as? Bool, false)
  }

  func testImportWithoutAnnotateShortcutSectionDoesNotResetActionEnablement() {
    let defaults = UserDefaultsFactory.make()
    let manager = AnnotateShortcutManager.shared
    let original = manager.isActionShortcutEnabled(for: .copyAndClose)
    manager.setActionShortcutEnabled(false, for: .copyAndClose)
    defer { manager.setActionShortcutEnabled(original, for: .copyAndClose) }

    let source = """
    schema_version = 1

    [capture.screenshot]
    show_cursor = true
    """

    let result = SnapzyConfigurationImporter.importTOML(source, defaults: defaults)

    XCTAssertFalse(result.hasErrors)
    XCTAssertFalse(manager.isActionShortcutEnabled(for: .copyAndClose))
  }
}
