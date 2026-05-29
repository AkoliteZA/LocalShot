//
//  SnapzyDeepLinkHandlerTests.swift
//  SnapzyTests
//
//  Unit tests for localshot:// automation URL parsing.
//

import XCTest
@testable import LocalShot

final class SnapzyDeepLinkHandlerTests: XCTestCase {

  func testCanonicalRoutesParseExpectedActions() throws {
    let cases: [(String, SnapzyDeepLinkAction)] = [
      ("localshot://capture/fullscreen", .captureFullscreen),
      ("localshot://capture/area", .captureArea),
      ("localshot://capture/application", .captureApplication),
      ("localshot://capture/area-annotate", .captureAreaAnnotate),
      ("localshot://capture/scrolling", .captureScrolling),
      ("localshot://capture/ocr", .captureOCR),
      ("localshot://capture/object-cutout", .captureObjectCutout),
      ("localshot://record/screen", .recordScreen),
      ("localshot://record/application", .recordApplication),
      ("localshot://open/annotate", .openAnnotate),
      ("localshot://open/history", .openHistory),
      ("localshot://show/shortcuts", .showShortcuts),
      ("localshot://settings", .openSettings(nil)),
    ]

    for (urlString, expectedAction) in cases {
      let url = try XCTUnwrap(URL(string: urlString))
      XCTAssertEqual(SnapzyDeepLinkAction(url: url), expectedAction, urlString)
    }
  }

  func testApplicationCaptureAliasesParseExpectedAction() throws {
    let aliases = [
      "localshot://capture/window",
      "localshot://application-capture",
      "localshot://window-capture",
      "localshot://screenshot/window",
    ]

    for urlString in aliases {
      let url = try XCTUnwrap(URL(string: urlString))
      XCTAssertEqual(SnapzyDeepLinkAction(url: url), .captureApplication, urlString)
    }
  }

  func testApplicationRecordingAliasesParseExpectedAction() throws {
    let aliases = [
      "localshot://record/window",
      "localshot://application-recording",
      "localshot://window-recording",
      "localshot://recording/window",
    ]

    for urlString in aliases {
      let url = try XCTUnwrap(URL(string: urlString))
      XCTAssertEqual(SnapzyDeepLinkAction(url: url), .recordApplication, urlString)
    }
  }

  func testSettingsTabRoutesParseExpectedTabs() throws {
    let cases: [(String, PreferencesTab)] = [
      ("general", .general),
      ("capture", .capture),
      ("annotate", .annotate),
      ("quick-access", .quickAccess),
      ("history", .history),
      ("shortcuts", .shortcuts),
      ("permissions", .permissions),
      ("privacy", .about),
      ("advanced", .advanced),
      ("about", .about),
    ]

    for (tabName, expectedTab) in cases {
      let queryURL = try XCTUnwrap(URL(string: "localshot://settings?tab=\(tabName)"))
      XCTAssertEqual(SnapzyDeepLinkAction(url: queryURL), .openSettings(expectedTab), tabName)

      let pathURL = try XCTUnwrap(URL(string: "localshot://settings/\(tabName)"))
      XCTAssertEqual(SnapzyDeepLinkAction(url: pathURL), .openSettings(expectedTab), tabName)
    }
  }

  func testUnsupportedRoutesReturnNil() throws {
    let urls = [
      "https://capture/area",
      "localshot://",
      "localshot://capture/unknown",
      "localshot://record/stop",
      "localshot://open/video-editor",
      "localshot://open/cloud-uploads",
      "localshot://open/unknown",
    ]

    for urlString in urls {
      let url = try XCTUnwrap(URL(string: urlString))
      XCTAssertNil(SnapzyDeepLinkAction(url: url), urlString)
    }
  }
}
