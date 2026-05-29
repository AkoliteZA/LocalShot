//
//  ScreenCapturePermissionGate.swift
//  Snapzy
//
//  Shared guard for capture flows that require Screen Recording permission.
//

import Foundation

enum ScreenCapturePermissionGate {
  @discardableResult
  static func runIfAllowed(
    hasPermission: Bool,
    requestPermission: () -> Void,
    operation: () -> Void
  ) -> Bool {
    guard hasPermission else {
      requestPermission()
      return false
    }

    operation()
    return true
  }
}
