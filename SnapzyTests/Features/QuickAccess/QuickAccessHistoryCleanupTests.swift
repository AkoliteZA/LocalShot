//
//  QuickAccessHistoryCleanupTests.swift
//  SnapzyTests
//
//  Verify that user-initiated deletion from Quick Access also removes the
//  matching Capture History record, while auto-dismiss paths preserve it.
//

import XCTest
@testable import LocalShot

@MainActor
final class QuickAccessHistoryCleanupTests: XCTestCase {

  private var originalHistoryEnabled: Bool!
  private var testFiles: [URL] = []

  override func setUp() {
    super.setUp()
    originalHistoryEnabled = UserDefaults.standard.bool(forKey: PreferencesKeys.historyEnabled)
    UserDefaults.standard.set(true, forKey: PreferencesKeys.historyEnabled)
  }

  override func tearDown() async throws {
    QuickAccessManager.shared.dismissAll()

    for url in testFiles {
      CaptureHistoryStore.shared.removeByFilePath(url.path)
      try? FileManager.default.removeItem(at: url)
    }
    testFiles.removeAll()

    UserDefaults.standard.set(originalHistoryEnabled, forKey: PreferencesKeys.historyEnabled)
    try await super.tearDown()
  }

  // MARK: - Helpers

  private func createTestFile(in directory: URL, name: String? = nil) throws -> URL {
    let fileName = name ?? "test_\(UUID().uuidString).png"
    let fileURL = directory.appendingPathComponent(fileName)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("test".utf8).write(to: fileURL)
    testFiles.append(fileURL)
    return fileURL
  }

  // MARK: - Tests

  func testDeleteItem_removesHistoryRecordForTempFile() async throws {
    let fileURL = try createTestFile(in: TempCaptureManager.shared.tempCaptureDirectory)
    CaptureHistoryStore.shared.addCapture(url: fileURL, captureType: .screenshot)
    XCTAssertTrue(
      CaptureHistoryStore.shared.hasRecord(forFilePath: fileURL.path),
      "History record should exist before delete"
    )

    await QuickAccessManager.shared.addScreenshot(url: fileURL)
    let item = try XCTUnwrap(
      QuickAccessManager.shared.items.first { $0.url == fileURL },
      "Quick Access item should have been added"
    )

    QuickAccessManager.shared.deleteItem(id: item.id)

    XCTAssertFalse(
      CaptureHistoryStore.shared.hasRecord(forFilePath: fileURL.path),
      "History record should be removed after explicit delete"
    )
  }

  func testRemoveItem_preservesHistoryRecordForTempFile() async throws {
    let fileURL = try createTestFile(in: TempCaptureManager.shared.tempCaptureDirectory)
    CaptureHistoryStore.shared.addCapture(url: fileURL, captureType: .screenshot)
    XCTAssertTrue(
      CaptureHistoryStore.shared.hasRecord(forFilePath: fileURL.path),
      "History record should exist before dismiss"
    )

    await QuickAccessManager.shared.addScreenshot(url: fileURL)
    let item = try XCTUnwrap(
      QuickAccessManager.shared.items.first { $0.url == fileURL },
      "Quick Access item should have been added"
    )

    QuickAccessManager.shared.removeItem(id: item.id)

    XCTAssertTrue(
      CaptureHistoryStore.shared.hasRecord(forFilePath: fileURL.path),
      "History record should be preserved after auto-dismiss path"
    )
  }

  func testDeleteItem_removesHistoryRecordForSavedFile() async throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("SnapzyTests_DeleteSaved_\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let fileURL = try createTestFile(in: directory)

    CaptureHistoryStore.shared.addCapture(url: fileURL, captureType: .screenshot)
    XCTAssertTrue(
      CaptureHistoryStore.shared.hasRecord(forFilePath: fileURL.path),
      "History record should exist before delete"
    )

    await QuickAccessManager.shared.addScreenshot(url: fileURL)
    let item = try XCTUnwrap(
      QuickAccessManager.shared.items.first { $0.url == fileURL },
      "Quick Access item should have been added"
    )

    QuickAccessManager.shared.deleteItem(id: item.id)

    XCTAssertFalse(
      CaptureHistoryStore.shared.hasRecord(forFilePath: fileURL.path),
      "History record should be removed after explicit delete of saved file"
    )
  }
}
