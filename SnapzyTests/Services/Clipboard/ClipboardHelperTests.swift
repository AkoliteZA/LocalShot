//
//  ClipboardHelperTests.swift
//  SnapzyTests
//
//  Unit tests for ClipboardHelper format handling and file copy logic.
//

import AppKit
import XCTest
@testable import Snapzy

@MainActor
final class ClipboardHelperTests: XCTestCase {

  private var originalFormat: String?

  override func setUp() {
    super.setUp()
    originalFormat = UserDefaults.standard.string(forKey: PreferencesKeys.screenshotFormat)
  }

  override func tearDown() {
    if let originalFormat {
      UserDefaults.standard.set(originalFormat, forKey: PreferencesKeys.screenshotFormat)
    } else {
      UserDefaults.standard.removeObject(forKey: PreferencesKeys.screenshotFormat)
    }
    super.tearDown()
  }

  func testCopyFileURLs_emptyArray_noOp() {
    ClipboardHelper.copyFileURLs([])
    // Should not crash
  }

  func testCopyImageFromURL_missingFile_logsAndReturns() {
    let missingURL = URL(fileURLWithPath: "/tmp/\(UUID().uuidString)_nonexistent.png")
    ClipboardHelper.copyImage(from: missingURL)
    // Should not crash; pasteboard may be empty or unchanged
  }

  func testCopyImageFromURL_validFile_copiesToClipboard() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    guard let cgImage = TestImageFactory.solidColor(width: 10, height: 10) else {
      XCTFail("Failed to create test image")
      return
    }
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 10, height: 10))
    guard let data = AnnotateExporter.imageData(from: nsImage, for: "png") else {
      XCTFail("Failed to encode test image")
      return
    }
    let fileURL = tempDir.appendingPathComponent("test.png")
    try data.write(to: fileURL)

    ClipboardHelper.copyImage(from: fileURL)
    let pasteboard = NSPasteboard.general
    let item = try XCTUnwrap(pasteboard.pasteboardItems?.first)
    XCTAssertEqual(pasteboard.pasteboardItems?.count, 1)
    XCTAssertTrue(item.types.contains(.fileURL))
    XCTAssertTrue(item.types.contains(.png))
    XCTAssertTrue(item.types.contains(.tiff))
    XCTAssertEqual((pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL])?.count, 1)
    XCTAssertEqual((pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage])?.count, 1)
  }

  func testCopyRenderedImage_withPNGFormat() throws {
    UserDefaults.standard.set(ImageFormatOption.png.rawValue, forKey: PreferencesKeys.screenshotFormat)
    guard let cgImage = TestImageFactory.solidColor(width: 10, height: 10) else {
      XCTFail("Failed to create test image")
      return
    }
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 10, height: 10))
    ClipboardHelper.copyImage(nsImage)
    let pasteboard = NSPasteboard.general
    let item = try XCTUnwrap(pasteboard.pasteboardItems?.first)
    XCTAssertEqual(pasteboard.pasteboardItems?.count, 1)
    XCTAssertTrue(item.types.contains(.fileURL))
    XCTAssertTrue(item.types.contains(.png))
    XCTAssertTrue(item.types.contains(.tiff))
    XCTAssertEqual((pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL])?.count, 1)
    XCTAssertEqual((pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage])?.count, 1)
  }

  func testCopyRenderedImage_withJPEGFormat() throws {
    UserDefaults.standard.set(ImageFormatOption.jpeg.rawValue, forKey: PreferencesKeys.screenshotFormat)
    guard let cgImage = TestImageFactory.solidColor(width: 10, height: 10) else {
      XCTFail("Failed to create test image")
      return
    }
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 10, height: 10))
    ClipboardHelper.copyImage(nsImage)
    let pasteboard = NSPasteboard.general
    let item = try XCTUnwrap(pasteboard.pasteboardItems?.first)
    let jpegType = NSPasteboard.PasteboardType("public.jpeg")
    XCTAssertEqual(pasteboard.pasteboardItems?.count, 1)
    XCTAssertTrue(item.types.contains(.fileURL))
    XCTAssertTrue(item.types.contains(jpegType))
    XCTAssertTrue(item.types.contains(.tiff))
    XCTAssertEqual((pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL])?.count, 1)
    XCTAssertEqual((pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage])?.count, 1)
  }

  func testCopyImageFromURL_undecodableWebP_keepsSingleFileAndOriginalDataItem() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let fileURL = tempDir.appendingPathComponent("test.webp")
    try Data([0x52, 0x49, 0x46, 0x46]).write(to: fileURL)

    ClipboardHelper.copyImage(from: fileURL)
    let pasteboard = NSPasteboard.general
    let item = try XCTUnwrap(pasteboard.pasteboardItems?.first)
    let webPType = NSPasteboard.PasteboardType("org.webmproject.webp")

    XCTAssertEqual(pasteboard.pasteboardItems?.count, 1)
    XCTAssertTrue(item.types.contains(.fileURL))
    XCTAssertTrue(item.types.contains(webPType))
    XCTAssertFalse(item.types.contains(.tiff))
    XCTAssertEqual((pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL])?.count, 1)
  }
}
