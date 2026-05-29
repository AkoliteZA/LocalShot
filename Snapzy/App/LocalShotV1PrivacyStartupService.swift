//
//  LocalShotV1PrivacyStartupService.swift
//  Snapzy
//
//  Enforces local-only startup cleanup for the v1 build.
//

import Foundation

@MainActor
enum LocalShotV1PrivacyStartupService {
  private static let cloudDefaultsKeys = [
    PreferencesKeys.cloudProviderType,
    PreferencesKeys.cloudBucket,
    PreferencesKeys.cloudRegion,
    PreferencesKeys.cloudEndpoint,
    PreferencesKeys.cloudCustomDomain,
    PreferencesKeys.cloudExpireTime,
    PreferencesKeys.cloudPasswordSkipped,
    PreferencesKeys.cloudUsageStatsCache,
    PreferencesKeys.cloudUploadsFloatingPosition,
  ]

  static func run(defaults: UserDefaults = .standard) {
    guard !LocalShotV1Policy.cloudUploadsEnabled else { return }

    clearCloudDefaults(defaults: defaults)
    CloudManager.shared.clearConfiguration()
  }

  static func clearCloudDefaults(defaults: UserDefaults) {
    for key in cloudDefaultsKeys {
      defaults.removeObject(forKey: key)
    }

    defaults.set(false, forKey: PreferencesKeys.cloudConfigured)
    defaults.set(false, forKey: PreferencesKeys.cloudPasswordEnabled)
  }
}
