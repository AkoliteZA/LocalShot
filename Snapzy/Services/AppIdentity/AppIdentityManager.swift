//
//  AppIdentityManager.swift
//  Snapzy
//
//  Tracks bundle identity health for permission-sensitive release builds.
//

import Combine
import Foundation
import Security

enum AppBundleIdentity {
  static let expected = LocalShotBrand.bundleIdentifier
}

enum AppIdentityIssue: Equatable, Hashable {
  case unexpectedBundleIdentifier(String?)
  case invalidBundleSignature
  case outsideApplications(URL)
  case quarantined

  var description: String {
    switch self {
    case .unexpectedBundleIdentifier(let bundleIdentifier):
      let currentIdentifier = bundleIdentifier ?? "missing"
      return L10n.AppIdentity.unexpectedBundleIdentifier(currentIdentifier)
    case .invalidBundleSignature:
      return L10n.AppIdentity.invalidSignature
    case .outsideApplications(let bundleURL):
      return L10n.AppIdentity.outsideApplications(bundleURL.path)
    case .quarantined:
      return L10n.AppIdentity.quarantined
    }
  }
}

enum AppIdentityWarning: Equatable, Hashable {
  case adHocSignature

  var description: String {
    switch self {
    case .adHocSignature:
      return L10n.AppIdentity.adHocSignature
    }
  }
}

struct AppIdentityHealth: Equatable {
  let bundleURL: URL
  let issues: [AppIdentityIssue]
  let warnings: [AppIdentityWarning]

  var isHealthy: Bool {
    issues.isEmpty
  }

  var needsAttention: Bool {
    !issues.isEmpty || !warnings.isEmpty
  }

  var summary: String {
    if issues.isEmpty {
      return L10n.AppIdentity.healthy
    }

    return issues.map(\.description).joined(separator: " ")
  }

  var warningSummary: String {
    warnings.map(\.description).joined(separator: " ")
  }

  var attentionMessages: [String] {
    issues.map(\.description) + warnings.map(\.description)
  }
}

@MainActor
final class AppIdentityManager: ObservableObject {
  static let shared = AppIdentityManager()

  @Published private(set) var health = AppIdentityHealth(
    bundleURL: Bundle.main.bundleURL,
    issues: [],
    warnings: []
  )

  private init() {
    refresh()
  }

  func refresh() {
    health = Self.evaluate()
  }

  private static func evaluate() -> AppIdentityHealth {
    let bundleURL = Bundle.main.bundleURL.standardizedFileURL
    var issues: [AppIdentityIssue] = []
    var warnings: [AppIdentityWarning] = []
    let quarantined = isQuarantined(bundleURL)

    if Bundle.main.bundleIdentifier != AppBundleIdentity.expected {
      issues.append(.unexpectedBundleIdentifier(Bundle.main.bundleIdentifier))
    }

    if quarantined && !bundleURL.path.hasPrefix("/Applications/") {
      issues.append(.outsideApplications(bundleURL))
    }

    if quarantined {
      issues.append(.quarantined)
    }

    if isAdHocSigned(bundleURL) {
      warnings.append(.adHocSignature)
    }

    // Skip strict signature validation in debug builds — Xcode uses ad-hoc
    // signing which always fails kSecCSStrictValidate, blocking the entire
    // permission flow during development.
    #if !DEBUG
    if !hasValidBundleSignature(bundleURL) {
      issues.append(.invalidBundleSignature)
    }
    #endif

    return AppIdentityHealth(bundleURL: bundleURL, issues: issues, warnings: warnings)
  }

  private static func isQuarantined(_ bundleURL: URL) -> Bool {
    let values = try? bundleURL.resourceValues(forKeys: [.quarantinePropertiesKey])
    return values?.quarantineProperties != nil
  }

  private static func hasValidBundleSignature(_ bundleURL: URL) -> Bool {
    var staticCode: SecStaticCode?
    let createStatus = SecStaticCodeCreateWithPath(bundleURL as CFURL, SecCSFlags(), &staticCode)
    guard createStatus == errSecSuccess, let staticCode else {
      return false
    }

    let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSCheckNestedCode | kSecCSStrictValidate)
    let verifyStatus = SecStaticCodeCheckValidity(staticCode, flags, nil)
    return verifyStatus == errSecSuccess
  }

  private static func isAdHocSigned(_ bundleURL: URL) -> Bool {
    var staticCode: SecStaticCode?
    let createStatus = SecStaticCodeCreateWithPath(bundleURL as CFURL, SecCSFlags(), &staticCode)
    guard createStatus == errSecSuccess, let staticCode else {
      return false
    }

    var signingInformation: CFDictionary?
    let copyStatus = SecCodeCopySigningInformation(
      staticCode,
      SecCSFlags(rawValue: kSecCSSigningInformation),
      &signingInformation
    )
    guard
      copyStatus == errSecSuccess,
      let information = signingInformation as? [String: Any]
    else {
      return false
    }

    let certificateKey = kSecCodeInfoCertificates as String
    let certificates = information[certificateKey] as? [SecCertificate]
    return certificates?.isEmpty ?? true
  }
}
