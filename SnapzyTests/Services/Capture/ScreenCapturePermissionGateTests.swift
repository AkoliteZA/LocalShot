//
//  ScreenCapturePermissionGateTests.swift
//  SnapzyTests
//
//  Regression coverage for capture entry points that require Screen Recording.
//

import XCTest
@testable import LocalShot

final class ScreenCapturePermissionGateTests: XCTestCase {
  func testRunRequestsPermissionAndBlocksOperationWhenPermissionMissing() {
    var requestCount = 0
    var operationCount = 0

    let didRun = ScreenCapturePermissionGate.runIfAllowed(
      hasPermission: false,
      requestPermission: { requestCount += 1 },
      operation: { operationCount += 1 }
    )

    XCTAssertFalse(didRun)
    XCTAssertEqual(requestCount, 1)
    XCTAssertEqual(operationCount, 0)
  }

  func testRunExecutesOperationWithoutRequestWhenPermissionGranted() {
    var requestCount = 0
    var operationCount = 0

    let didRun = ScreenCapturePermissionGate.runIfAllowed(
      hasPermission: true,
      requestPermission: { requestCount += 1 },
      operation: { operationCount += 1 }
    )

    XCTAssertTrue(didRun)
    XCTAssertEqual(requestCount, 0)
    XCTAssertEqual(operationCount, 1)
  }
}
