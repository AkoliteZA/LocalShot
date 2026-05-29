//
//  CaptureAreaMemoryTests.swift
//  SnapzyTests
//
//  Verifies screenshot previous-area persistence.
//

import CoreGraphics
import XCTest
@testable import LocalShot

final class CaptureAreaMemoryTests: XCTestCase {
  func testSaveAndLoadPreviousScreenshotArea() {
    let defaults = UserDefaultsFactory.make()
    let rect = CGRect(x: 120, y: 80, width: 640, height: 360)

    CaptureAreaMemory.save(rect, defaults: defaults)

    XCTAssertEqual(
      CaptureAreaMemory.load(
        defaults: defaults,
        visibleScreenFrames: [CGRect(x: 0, y: 0, width: 1440, height: 900)]
      ),
      rect
    )
  }

  func testLoadRejectsAreaOutsideCurrentScreens() {
    let defaults = UserDefaultsFactory.make()
    CaptureAreaMemory.save(
      CGRect(x: 1600, y: 1200, width: 640, height: 360),
      defaults: defaults
    )

    XCTAssertNil(
      CaptureAreaMemory.load(
        defaults: defaults,
        visibleScreenFrames: [CGRect(x: 0, y: 0, width: 1440, height: 900)]
      )
    )
  }

  func testLoadRejectsMalformedArea() {
    let defaults = UserDefaultsFactory.make()
    defaults.set(
      ["x": 10, "y": 20, "width": 0, "height": 100],
      forKey: PreferencesKeys.screenshotLastAreaRect
    )

    XCTAssertNil(
      CaptureAreaMemory.load(
        defaults: defaults,
        visibleScreenFrames: [CGRect(x: 0, y: 0, width: 1440, height: 900)]
      )
    )
  }
}
