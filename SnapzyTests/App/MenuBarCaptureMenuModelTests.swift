//
//  MenuBarCaptureMenuModelTests.swift
//  SnapzyTests
//
//  Regression coverage for the LocalShot menu bar capture popover inventory.
//

import XCTest
@testable import LocalShot

final class MenuBarCaptureMenuModelTests: XCTestCase {
  func testLocalShotV1MenuMatchesMockupInventory() {
    let sections = MenuBarCaptureMenuModel.sections(
      hasScreenCapturePermission: true,
      hasPreviousCaptureArea: true,
      isRecordingActive: false,
      isScrollingCaptureActive: false
    )

    XCTAssertEqual(MenuBarCaptureMenuModel.headerTitle, "LocalShot")
    XCTAssertEqual(MenuBarCaptureMenuModel.privacyBadgeTitle, "Local only")
    XCTAssertEqual(MenuBarCaptureMenuModel.headerDisplayTitle, "LocalShot    Local only")
    XCTAssertEqual(sections.map(\.title), ["Capture", "Recording", "Utility"])
    XCTAssertEqual(
      sections[0].items.map(\.title),
      [
        "Capture Area",
        "Capture Window",
        "Capture Full Screen",
        "Capture Previous Area",
        "Scrolling Capture",
      ]
    )
    XCTAssertEqual(
      sections[1].items.map(\.title),
      [
        "Record Area",
        "Record Full Screen",
        "GIF Recording",
      ]
    )
    XCTAssertEqual(sections[2].items.map(\.title), ["History", "Settings"])

    let allTitles = sections.flatMap(\.items).map(\.title).joined(separator: " ")
    for forbiddenTerm in ["Upload", "Cloud", "Account", "Sign In", "Update"] {
      XCTAssertFalse(allTitles.localizedCaseInsensitiveContains(forbiddenTerm))
    }
  }

  func testLocalShotV1MenuStateKeepsUnavailableRowsVisibleButDisabled() {
    let sections = MenuBarCaptureMenuModel.sections(
      hasScreenCapturePermission: false,
      hasPreviousCaptureArea: false,
      isRecordingActive: true,
      isScrollingCaptureActive: true
    )

    let itemsByID = Dictionary(
      uniqueKeysWithValues: sections.flatMap(\.items).map { ($0.id, $0) }
    )

    XCTAssertEqual(itemsByID[.captureArea]?.isEnabled, false)
    XCTAssertEqual(itemsByID[.captureWindow]?.isEnabled, false)
    XCTAssertEqual(itemsByID[.captureFullScreen]?.isEnabled, false)
    XCTAssertEqual(itemsByID[.capturePreviousArea]?.isEnabled, false)
    XCTAssertEqual(itemsByID[.scrollingCapture]?.isEnabled, false)
    XCTAssertEqual(itemsByID[.recordArea]?.isEnabled, false)
    XCTAssertEqual(itemsByID[.recordFullScreen]?.isEnabled, false)
    XCTAssertEqual(itemsByID[.gifRecording]?.isEnabled, false)
    XCTAssertEqual(itemsByID[.history]?.isEnabled, true)
    XCTAssertEqual(itemsByID[.settings]?.isEnabled, true)
  }
}
