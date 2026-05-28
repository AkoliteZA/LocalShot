//
//  CaptureOutputNamingTests.swift
//  SnapzyTests
//
//  Unit tests for CaptureOutputNaming filename generation and sanitization.
//

import XCTest
@testable import LocalShot

final class CaptureOutputNamingTests: XCTestCase {

  // Fixed date: 2026-01-15 14:30:45.123 UTC
  private let fixedDate = Date(timeIntervalSince1970: 1_768_512_645.123)
  private var tempDirectory: URL!
  private var defaults: UserDefaults!

  override func setUp() {
    super.setUp()
    tempDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("SnapzyTests_CaptureOutputNaming_\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    defaults = UserDefaultsFactory.make()
  }

  override func tearDown() {
    if let tempDirectory {
      try? FileManager.default.removeItem(at: tempDirectory)
    }
    super.tearDown()
  }

  // MARK: - resolveBaseName with custom name

  func testResolveBaseName_withCustomName_returnsSanitizedName() {
    let result = CaptureOutputNaming.resolveBaseName(
      customName: "My Screenshot",
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertEqual(result, "My Screenshot")
  }

  func testResolveBaseName_withNilCustomName_fallsBackToTemplate() {
    let result = CaptureOutputNaming.resolveBaseName(
      customName: nil,
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    // Default template: "LocalShot_{datetime}_{ms}"
    XCTAssertTrue(result.hasPrefix("LocalShot_"), "Expected template-based name, got: \(result)")
    XCTAssertTrue(result.contains("_"), "Expected datetime separators")
  }

  func testResolveBaseName_withEmptyCustomName_fallsBackToTemplate() {
    let result = CaptureOutputNaming.resolveBaseName(
      customName: "",
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertTrue(result.hasPrefix("LocalShot_"), "Expected template-based name, got: \(result)")
  }

  func testResolveBaseName_withWhitespaceOnlyCustomName_fallsBackToTemplate() {
    let result = CaptureOutputNaming.resolveBaseName(
      customName: "   ",
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertTrue(result.hasPrefix("LocalShot_"))
  }

  // MARK: - Template Token Expansion

  func testResolveBaseName_typeToken_screenshot() {
    defaults.set("{type}_capture", forKey: PreferencesKeys.screenshotFileNameTemplate)

    let result = CaptureOutputNaming.resolveBaseName(
      customName: nil,
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertEqual(result, "screenshot_capture")
  }

  func testResolveBaseName_typeToken_recording() {
    defaults.set("{type}_file", forKey: PreferencesKeys.recordingFileNameTemplate)

    let result = CaptureOutputNaming.resolveBaseName(
      customName: nil,
      kind: .recording,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertEqual(result, "recording_file")
  }

  func testResolveBaseName_datetimeToken() {
    defaults.set("Snap_{datetime}", forKey: PreferencesKeys.screenshotFileNameTemplate)

    let result = CaptureOutputNaming.resolveBaseName(
      customName: nil,
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )

    // datetime format: yyyy-MM-dd_HH-mm-ss
    // Verify it contains a date-like pattern
    let datePattern = #"\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}"#
    XCTAssertNotNil(
      result.range(of: datePattern, options: .regularExpression),
      "Expected datetime pattern in: \(result)"
    )
  }

  func testResolveBaseName_msToken() {
    defaults.set("file_{ms}", forKey: PreferencesKeys.screenshotFileNameTemplate)

    let result = CaptureOutputNaming.resolveBaseName(
      customName: nil,
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )

    // ms token should be 3 digits
    let msPattern = #"file_\d{3}"#
    XCTAssertNotNil(
      result.range(of: msPattern, options: .regularExpression),
      "Expected ms pattern in: \(result)"
    )
  }

  func testResolveBaseName_timestampToken() {
    defaults.set("ts_{timestamp}", forKey: PreferencesKeys.screenshotFileNameTemplate)

    let result = CaptureOutputNaming.resolveBaseName(
      customName: nil,
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )

    let expected = "ts_\(Int(fixedDate.timeIntervalSince1970))"
    XCTAssertEqual(result, expected)
  }

  // MARK: - Sanitization

  func testSanitize_invalidFilenameCharacters_replacedWithUnderscore() {
    let result = CaptureOutputNaming.resolveBaseName(
      customName: "file/with\\bad:chars?test",
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertFalse(result.contains("/"))
    XCTAssertFalse(result.contains("\\"))
    XCTAssertFalse(result.contains(":"))
    XCTAssertFalse(result.contains("?"))
  }

  func testSanitize_consecutiveUnderscores_collapsed() {
    let result = CaptureOutputNaming.resolveBaseName(
      customName: "file___name",
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertFalse(result.contains("___"))
    XCTAssertTrue(result.contains("_"))
  }

  func testSanitize_knownExtension_stripped() {
    let result = CaptureOutputNaming.resolveBaseName(
      customName: "myfile.png",
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertEqual(result, "myfile")
  }

  func testSanitize_knownExtension_jpegStripped() {
    let result = CaptureOutputNaming.resolveBaseName(
      customName: "capture.jpeg",
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertEqual(result, "capture")
  }

  func testSanitize_unknownExtension_preserved() {
    let result = CaptureOutputNaming.resolveBaseName(
      customName: "document.pdf",
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertEqual(result, "document.pdf")
  }

  func testSanitize_trimmingDotsAndSpaces() {
    let result = CaptureOutputNaming.resolveBaseName(
      customName: "  .file. ",
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )
    XCTAssertEqual(result, "file")
  }

  // MARK: - makeUniqueFileURL

  func testMakeUniqueFileURL_noCollision_returnsBaseURL() {
    let result = CaptureOutputNaming.makeUniqueFileURL(
      in: tempDirectory,
      baseName: "test_capture",
      fileExtension: "png"
    )
    XCTAssertEqual(result.lastPathComponent, "test_capture.png")
  }

  func testMakeUniqueFileURL_withCollision_appendsSuffix() throws {
    // Create first file
    let firstFile = tempDirectory.appendingPathComponent("test_capture.png")
    try Data("test".utf8).write(to: firstFile)

    let result = CaptureOutputNaming.makeUniqueFileURL(
      in: tempDirectory,
      baseName: "test_capture",
      fileExtension: "png"
    )
    XCTAssertEqual(result.lastPathComponent, "test_capture_2.png")
  }

  func testMakeUniqueFileURL_withMultipleCollisions_incrementsSuffix() throws {
    // Create first two files
    try Data("test".utf8).write(to: tempDirectory.appendingPathComponent("shot.png"))
    try Data("test".utf8).write(to: tempDirectory.appendingPathComponent("shot_2.png"))

    let result = CaptureOutputNaming.makeUniqueFileURL(
      in: tempDirectory,
      baseName: "shot",
      fileExtension: "png"
    )
    XCTAssertEqual(result.lastPathComponent, "shot_3.png")
  }

  // MARK: - resolvedTemplate

  func testResolvedTemplate_withSavedValue_returnsSavedValue() {
    defaults.set("Custom_{date}", forKey: PreferencesKeys.screenshotFileNameTemplate)

    let result = CaptureOutputNaming.resolvedTemplate(for: .screenshot, defaults: defaults)
    XCTAssertEqual(result, "Custom_{date}")
  }

  func testResolvedTemplate_withEmptyValue_returnsDefault() {
    defaults.set("", forKey: PreferencesKeys.screenshotFileNameTemplate)

    let result = CaptureOutputNaming.resolvedTemplate(for: .screenshot, defaults: defaults)
    XCTAssertEqual(result, CaptureOutputKind.screenshot.defaultTemplate)
  }

  func testResolvedTemplate_withMissingKey_returnsDefault() {
    defaults.removeObject(forKey: PreferencesKeys.screenshotFileNameTemplate)

    let result = CaptureOutputNaming.resolvedTemplate(for: .screenshot, defaults: defaults)
    XCTAssertEqual(result, CaptureOutputKind.screenshot.defaultTemplate)
  }

  func testResolvedTemplate_recording_returnsRecordingDefault() {
    defaults.removeObject(forKey: PreferencesKeys.recordingFileNameTemplate)

    let result = CaptureOutputNaming.resolvedTemplate(for: .recording, defaults: defaults)
    XCTAssertEqual(result, CaptureOutputKind.recording.defaultTemplate)
  }

  // MARK: - CaptureOutputKind Properties

  func testCaptureOutputKind_defaultTemplates() {
    XCTAssertEqual(CaptureOutputKind.screenshot.defaultTemplate, "LocalShot_{datetime}_{ms}")
    XCTAssertEqual(CaptureOutputKind.recording.defaultTemplate, "LocalShot_Recording_{datetime}")
  }

  func testCaptureOutputKind_typeTokenValues() {
    XCTAssertEqual(CaptureOutputKind.screenshot.typeTokenValue, "screenshot")
    XCTAssertEqual(CaptureOutputKind.recording.typeTokenValue, "recording")
  }

  // MARK: - Fallback Name

  func testResolveBaseName_invalidTemplate_usesFallbackName() {
    // Template that resolves to empty after sanitization
    defaults.set("...", forKey: PreferencesKeys.screenshotFileNameTemplate)

    let result = CaptureOutputNaming.resolveBaseName(
      customName: nil,
      kind: .screenshot,
      date: fixedDate,
      defaults: defaults
    )

    // Fallback format: "LocalShot_{yyyy-MM-dd_HH-mm-ss-SSS}"
    XCTAssertTrue(result.hasPrefix("LocalShot_"), "Expected fallback name, got: \(result)")
  }
}
