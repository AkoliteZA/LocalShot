//
//  CaptureAreaMemory.swift
//  Snapzy
//
//  Stores the last manual screenshot area for quick recapture.
//

import AppKit
import CoreGraphics
import Foundation

enum CaptureAreaMemory {
  static func save(_ rect: CGRect, defaults: UserDefaults = .standard) {
    guard isUsable(rect) else { return }

    defaults.set(
      [
        "x": Double(rect.origin.x),
        "y": Double(rect.origin.y),
        "width": Double(rect.width),
        "height": Double(rect.height),
      ],
      forKey: PreferencesKeys.screenshotLastAreaRect
    )
  }

  static func load(
    defaults: UserDefaults = .standard,
    visibleScreenFrames: [CGRect] = NSScreen.screens.map(\.frame)
  ) -> CGRect? {
    guard let rectDict = defaults.dictionary(forKey: PreferencesKeys.screenshotLastAreaRect),
          let x = numberValue(for: "x", in: rectDict),
          let y = numberValue(for: "y", in: rectDict),
          let width = numberValue(for: "width", in: rectDict),
          let height = numberValue(for: "height", in: rectDict)
    else {
      return nil
    }

    let rect = CGRect(x: x, y: y, width: width, height: height)
    guard isUsable(rect) else { return nil }

    if visibleScreenFrames.isEmpty {
      return rect
    }

    guard visibleScreenFrames.contains(where: { $0.intersects(rect) }) else {
      return nil
    }

    return rect
  }

  private static func numberValue(for key: String, in dictionary: [String: Any]) -> CGFloat? {
    switch dictionary[key] {
    case let value as CGFloat:
      return value
    case let value as Double:
      return CGFloat(value)
    case let value as Float:
      return CGFloat(value)
    case let value as Int:
      return CGFloat(value)
    case let value as NSNumber:
      return CGFloat(truncating: value)
    default:
      return nil
    }
  }

  private static func isUsable(_ rect: CGRect) -> Bool {
    rect.origin.x.isFinite
      && rect.origin.y.isFinite
      && rect.width.isFinite
      && rect.height.isFinite
      && rect.width > 0
      && rect.height > 0
  }
}
