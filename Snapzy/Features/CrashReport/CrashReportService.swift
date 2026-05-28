//
//  CrashReportService.swift
//  Snapzy
//
//  Problem reporting is intentionally disabled for LocalShot v1.
//

import AppKit

enum CrashReportService {
  static let bugReportURL = URL(fileURLWithPath: "/dev/null")

  @MainActor
  @discardableResult
  static func presentAlert() -> Bool {
    let alert = NSAlert()
    alert.messageText = "Problem reporting is disabled"
    alert.informativeText = "LocalShot v1 does not upload diagnostics or open external issue-reporting services."
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
    return false
  }
}
