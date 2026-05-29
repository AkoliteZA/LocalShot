//
//  MicrophonePermissionRecoveryTests.swift
//  SnapzyTests
//
//  Regression coverage for microphone permission recovery copy and action.
//

import AVFoundation
import XCTest
@testable import LocalShot

final class MicrophonePermissionRecoveryTests: XCTestCase {
  func testNotDeterminedUsesNativePermissionPrompt() {
    XCTAssertEqual(
      MicrophonePermissionRecovery.action(for: .notDetermined),
      .requestSystemPrompt
    )
  }

  func testDeniedOrRestrictedOpenSystemSettings() {
    XCTAssertEqual(
      MicrophonePermissionRecovery.action(for: .denied),
      .openSystemSettings
    )
    XCTAssertEqual(
      MicrophonePermissionRecovery.action(for: .restricted),
      .openSystemSettings
    )
  }

  func testActionTitleMatchesRecoveryPath() {
    XCTAssertEqual(
      MicrophonePermissionRecovery.actionTitle(
        for: .notDetermined,
        grantAccessTitle: "Grant Access",
        openSettingsTitle: "Open Settings"
      ),
      "Grant Access"
    )
    XCTAssertEqual(
      MicrophonePermissionRecovery.actionTitle(
        for: .denied,
        grantAccessTitle: "Grant Access",
        openSettingsTitle: "Open Settings"
      ),
      "Open Settings"
    )
  }

  func testAuthorizedStatusIsGranted() {
    XCTAssertTrue(MicrophonePermissionRecovery.isGranted(.authorized))
    XCTAssertFalse(MicrophonePermissionRecovery.isGranted(.notDetermined))
    XCTAssertFalse(MicrophonePermissionRecovery.isGranted(.denied))
  }
}
