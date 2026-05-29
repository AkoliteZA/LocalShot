//
//  MenuBarCaptureMenuModel.swift
//  Snapzy
//
//  Pure menu inventory for the LocalShot menu bar capture popover.
//

import Foundation

enum MenuBarCaptureMenuItemID: String, Hashable {
  case captureArea
  case captureWindow
  case captureFullScreen
  case capturePreviousArea
  case scrollingCapture
  case recordArea
  case recordFullScreen
  case gifRecording
  case history
  case settings
}

struct MenuBarCaptureMenuItem: Equatable {
  let id: MenuBarCaptureMenuItemID
  let title: String
  let systemImage: String
  let isEnabled: Bool
}

struct MenuBarCaptureMenuSection: Equatable {
  let title: String
  let items: [MenuBarCaptureMenuItem]
}

enum MenuBarCaptureMenuModel {
  static let headerTitle = LocalShotBrand.appName
  static let privacyBadgeTitle = "Local only"
  static let headerDisplayTitle = "\(headerTitle)    \(privacyBadgeTitle)"

  static func sections(
    hasScreenCapturePermission: Bool,
    hasPreviousCaptureArea: Bool,
    isRecordingActive: Bool,
    isScrollingCaptureActive: Bool
  ) -> [MenuBarCaptureMenuSection] {
    [
      MenuBarCaptureMenuSection(
        title: "Capture",
        items: [
          MenuBarCaptureMenuItem(
            id: .captureArea,
            title: "Capture Area",
            systemImage: "crop",
            isEnabled: hasScreenCapturePermission
          ),
          MenuBarCaptureMenuItem(
            id: .captureWindow,
            title: "Capture Window",
            systemImage: "macwindow",
            isEnabled: hasScreenCapturePermission
          ),
          MenuBarCaptureMenuItem(
            id: .captureFullScreen,
            title: "Capture Full Screen",
            systemImage: "rectangle.dashed",
            isEnabled: hasScreenCapturePermission
          ),
          MenuBarCaptureMenuItem(
            id: .capturePreviousArea,
            title: "Capture Previous Area",
            systemImage: "rectangle.stack",
            isEnabled: hasScreenCapturePermission && hasPreviousCaptureArea
          ),
          MenuBarCaptureMenuItem(
            id: .scrollingCapture,
            title: "Scrolling Capture",
            systemImage: "arrow.up.and.down",
            isEnabled: hasScreenCapturePermission && !isScrollingCaptureActive
          ),
        ]
      ),
      MenuBarCaptureMenuSection(
        title: "Recording",
        items: [
          MenuBarCaptureMenuItem(
            id: .recordArea,
            title: "Record Area",
            systemImage: "record.circle",
            isEnabled: hasScreenCapturePermission && !isRecordingActive
          ),
          MenuBarCaptureMenuItem(
            id: .recordFullScreen,
            title: "Record Full Screen",
            systemImage: "display",
            isEnabled: hasScreenCapturePermission && !isRecordingActive
          ),
          MenuBarCaptureMenuItem(
            id: .gifRecording,
            title: "GIF Recording",
            systemImage: "photo.stack",
            isEnabled: hasScreenCapturePermission && !isRecordingActive
          ),
        ]
      ),
      MenuBarCaptureMenuSection(
        title: "Utility",
        items: [
          MenuBarCaptureMenuItem(
            id: .history,
            title: "History",
            systemImage: "clock.arrow.circlepath",
            isEnabled: true
          ),
          MenuBarCaptureMenuItem(
            id: .settings,
            title: "Settings",
            systemImage: "gear",
            isEnabled: true
          ),
        ]
      ),
    ]
  }
}
