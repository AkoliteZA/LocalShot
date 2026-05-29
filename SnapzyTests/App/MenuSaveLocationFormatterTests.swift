//
//  MenuSaveLocationFormatterTests.swift
//  SnapzyTests
//
//  Regression coverage for the menu bar save-location footer.
//

import Foundation
import XCTest
@testable import LocalShot

final class MenuSaveLocationFormatterTests: XCTestCase {
  func testTitleUsesHomeRelativePathForUserDirectory() {
    let home = URL(fileURLWithPath: "/Users/localshot", isDirectory: true)

    XCTAssertEqual(
      MenuSaveLocationFormatter.title(
        for: "/Users/localshot/Pictures/LocalShot",
        homeDirectory: home,
        defaultPath: "/Users/localshot/Pictures/LocalShot"
      ),
      "Saving to ~/Pictures/LocalShot"
    )
  }

  func testTitleUsesTildeForHomeDirectoryItself() {
    let home = URL(fileURLWithPath: "/Users/localshot", isDirectory: true)

    XCTAssertEqual(
      MenuSaveLocationFormatter.title(
        for: "/Users/localshot",
        homeDirectory: home,
        defaultPath: "/Users/localshot/Pictures/LocalShot"
      ),
      "Saving to ~"
    )
  }

  func testTitleKeepsExternalVolumeAbsolute() {
    let home = URL(fileURLWithPath: "/Users/localshot", isDirectory: true)

    XCTAssertEqual(
      MenuSaveLocationFormatter.title(
        for: "/Volumes/Captures/LocalShot",
        homeDirectory: home,
        defaultPath: "/Users/localshot/Pictures/LocalShot"
      ),
      "Saving to /Volumes/Captures/LocalShot"
    )
  }

  func testTitleFallsBackToDefaultPathWhenStoredPathIsBlank() {
    let home = URL(fileURLWithPath: "/Users/localshot", isDirectory: true)

    XCTAssertEqual(
      MenuSaveLocationFormatter.title(
        for: "  ",
        homeDirectory: home,
        defaultPath: "/Users/localshot/Pictures/LocalShot"
      ),
      "Saving to ~/Pictures/LocalShot"
    )
  }
}
