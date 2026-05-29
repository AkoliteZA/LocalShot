//
//  OnboardingFlowPrivacyTests.swift
//  SnapzyTests
//
//  Privacy guardrail tests for LocalShot first-run onboarding.
//

import XCTest
@testable import LocalShot

@MainActor
final class OnboardingFlowPrivacyTests: XCTestCase {
  func testDefaultOnboardingStepsDoNotPromptForDiagnosticsInLocalShotV1() throws {
    let steps = SplashOnboardingRootView.defaultOnboardingStepsForLocalShotV1

    XCTAssertEqual(steps, [.language, .permissions, .configAccess, .shortcuts, .completion])
    XCTAssertFalse(steps.contains(.diagnostics))
  }

  func testLocalShotV1DisablesPublicSupportPrompts() throws {
    XCTAssertFalse(LocalShotV1Policy.sponsorPromptsEnabled)
  }

  func testLocalShotV1DisablesProblemReports() throws {
    XCTAssertFalse(LocalShotV1Policy.problemReportsEnabled)
  }
}
