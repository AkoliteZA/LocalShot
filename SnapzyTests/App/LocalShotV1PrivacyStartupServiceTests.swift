//
//  LocalShotV1PrivacyStartupServiceTests.swift
//  SnapzyTests
//
//  Startup privacy guardrails for the local-only v1 build.
//

import XCTest
@testable import LocalShot

@MainActor
final class LocalShotV1PrivacyStartupServiceTests: XCTestCase {
  func testClearCloudDefaultsRemovesDormantCloudStateForLocalShotV1() {
    XCTAssertFalse(LocalShotV1Policy.cloudUploadsEnabled)

    let defaults = UserDefaultsFactory.make()
    defaults.set("awsS3", forKey: PreferencesKeys.cloudProviderType)
    defaults.set("private-bucket", forKey: PreferencesKeys.cloudBucket)
    defaults.set("us-west-2", forKey: PreferencesKeys.cloudRegion)
    defaults.set("https://r2.example", forKey: PreferencesKeys.cloudEndpoint)
    defaults.set("cdn.example", forKey: PreferencesKeys.cloudCustomDomain)
    defaults.set("day7", forKey: PreferencesKeys.cloudExpireTime)
    defaults.set(true, forKey: PreferencesKeys.cloudConfigured)
    defaults.set(true, forKey: PreferencesKeys.cloudPasswordEnabled)
    defaults.set(true, forKey: PreferencesKeys.cloudPasswordSkipped)
    defaults.set(Data("usage".utf8), forKey: PreferencesKeys.cloudUsageStatsCache)
    defaults.set("bottomRight", forKey: PreferencesKeys.cloudUploadsFloatingPosition)

    LocalShotV1PrivacyStartupService.clearCloudDefaults(defaults: defaults)

    XCTAssertNil(defaults.object(forKey: PreferencesKeys.cloudProviderType))
    XCTAssertNil(defaults.object(forKey: PreferencesKeys.cloudBucket))
    XCTAssertNil(defaults.object(forKey: PreferencesKeys.cloudRegion))
    XCTAssertNil(defaults.object(forKey: PreferencesKeys.cloudEndpoint))
    XCTAssertNil(defaults.object(forKey: PreferencesKeys.cloudCustomDomain))
    XCTAssertNil(defaults.object(forKey: PreferencesKeys.cloudExpireTime))
    XCTAssertNil(defaults.object(forKey: PreferencesKeys.cloudPasswordSkipped))
    XCTAssertNil(defaults.object(forKey: PreferencesKeys.cloudUsageStatsCache))
    XCTAssertNil(defaults.object(forKey: PreferencesKeys.cloudUploadsFloatingPosition))
    XCTAssertFalse(defaults.bool(forKey: PreferencesKeys.cloudConfigured))
    XCTAssertFalse(defaults.bool(forKey: PreferencesKeys.cloudPasswordEnabled))
  }

  func testClearCloudDefaultsDisablesDiagnosticsForLocalShotV1() {
    let defaults = UserDefaultsFactory.make()
    defaults.set(true, forKey: PreferencesKeys.diagnosticsEnabled)

    LocalShotV1PrivacyStartupService.clearCloudDefaults(defaults: defaults)

    XCTAssertEqual(
      defaults.object(forKey: PreferencesKeys.diagnosticsEnabled) as? Bool,
      LocalShotV1Policy.diagnosticsEnabledByDefault
    )
  }

  func testClearCloudDefaultsMigratesPicturesRootExportLocationToLocalShotFolder() {
    let defaults = UserDefaultsFactory.make()
    defaults.set(
      LocalShotBrand.defaultExportDirectory.deletingLastPathComponent().path,
      forKey: PreferencesKeys.exportLocation
    )

    LocalShotV1PrivacyStartupService.clearCloudDefaults(defaults: defaults)

    XCTAssertEqual(defaults.string(forKey: PreferencesKeys.exportLocation), LocalShotBrand.defaultExportDirectory.path)
  }
}
