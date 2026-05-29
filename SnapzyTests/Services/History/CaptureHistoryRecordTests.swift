//
//  CaptureHistoryRecordTests.swift
//  SnapzyTests
//
//  Unit tests for capture history record presentation helpers.
//

import Foundation
import XCTest
@testable import LocalShot

final class CaptureHistoryRecordTests: XCTestCase {

  func testFormattedDuration_formatsFiniteNonNegativeDurations() {
    XCTAssertEqual(makeRecord(duration: 65.9).formattedDuration, "01:05s")
    XCTAssertEqual(makeRecord(duration: 0).formattedDuration, "00:00s")
  }

  func testFormattedDuration_omitsInvalidDurations() {
    XCTAssertNil(makeRecord(duration: nil).formattedDuration)
    XCTAssertNil(makeRecord(duration: -1).formattedDuration)
    XCTAssertNil(makeRecord(duration: .infinity).formattedDuration)
  }

  func testFileURLAndFileExistsReflectStoredPath() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("SnapzyTests_HistoryRecord_\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let fileURL = directory.appendingPathComponent("capture.png")
    try Data("capture".utf8).write(to: fileURL)

    let record = makeRecord(filePath: fileURL.path)

    XCTAssertEqual(record.fileURL, fileURL)
    XCTAssertTrue(record.fileExists)
  }

  func testThumbnailURLRequiresExistingThumbnailFile() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("SnapzyTests_HistoryThumbnail_\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let thumbnailURL = directory.appendingPathComponent("thumb.png")
    let missingThumbnailURL = directory.appendingPathComponent("missing.png")
    try Data("thumb".utf8).write(to: thumbnailURL)

    XCTAssertEqual(makeRecord(thumbnailPath: thumbnailURL.path).thumbnailURL, thumbnailURL)
    XCTAssertNil(makeRecord(thumbnailPath: missingThumbnailURL.path).thumbnailURL)
    XCTAssertNil(makeRecord(thumbnailPath: nil).thumbnailURL)
  }

  func testHistoryOpenDestinationRoutesVideoAndGIFOutsideComplexEditorForLocalShotV1() {
    XCTAssertFalse(LocalShotV1Policy.complexVideoEditorEntryPointsEnabled)

    XCTAssertEqual(HistoryItemOpenDestination.destination(for: .screenshot), .annotate)
    XCTAssertEqual(HistoryItemOpenDestination.destination(for: .video), .openFileExternally)
    XCTAssertEqual(HistoryItemOpenDestination.destination(for: .gif), .openFileExternally)
  }

  func testHistoryDetailActionsMatchLocalShotMockupForScreenshots() {
    let titles = HistoryRecordDetailAction.actions(for: .screenshot).map(\.title)

    XCTAssertEqual(titles, [
      "Open",
      "Copy",
      "Annotate",
      "Pin",
      "Reveal in Finder",
      "Delete",
    ])
  }

  func testHistoryDetailActionsAvoidScreenshotOnlyToolsForMedia() {
    let videoTitles = HistoryRecordDetailAction.actions(for: .video).map(\.title)
    let gifTitles = HistoryRecordDetailAction.actions(for: .gif).map(\.title)

    XCTAssertEqual(videoTitles, ["Open", "Copy", "Reveal in Finder", "Delete"])
    XCTAssertEqual(gifTitles, ["Open", "Copy", "Reveal in Finder", "Delete"])
  }

  private func makeRecord(
    filePath: String = "/tmp/capture.png",
    duration: TimeInterval? = 12,
    thumbnailPath: String? = nil
  ) -> CaptureHistoryRecord {
    CaptureHistoryRecord(
      id: UUID(),
      filePath: filePath,
      fileName: URL(fileURLWithPath: filePath).lastPathComponent,
      captureType: .video,
      fileSize: 1024,
      capturedAt: Date(timeIntervalSince1970: 1_700_000_000),
      width: 640,
      height: 360,
      duration: duration,
      thumbnailPath: thumbnailPath,
      isDeleted: false
    )
  }
}
