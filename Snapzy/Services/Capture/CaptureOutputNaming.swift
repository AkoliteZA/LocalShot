//
//  CaptureOutputNaming.swift
//  Snapzy
//
//  Shared output filename generation for screenshots and recordings.
//

import Foundation

enum CaptureOutputKind {
  case screenshot
  case recording

  var defaultTemplate: String {
    switch self {
    case .screenshot:
      return "LocalShot_{datetime}_{ms}"
    case .recording:
      return "LocalShot_Recording_{datetime}"
    }
  }

  var typeTokenValue: String {
    switch self {
    case .screenshot:
      return "screenshot"
    case .recording:
      return "recording"
    }
  }

  var templatePreferenceKey: String {
    switch self {
    case .screenshot:
      return PreferencesKeys.screenshotFileNameTemplate
    case .recording:
      return PreferencesKeys.recordingFileNameTemplate
    }
  }
}

enum CaptureOutputNaming {
  private static let invalidFilenameCharacters = CharacterSet(charactersIn: "/\\:?%*|\"<>\n\r\t")
  private static let knownExtensions: Set<String> = ["png", "jpg", "jpeg", "webp", "mov", "mp4", "gif"]

  static func resolveBaseName(
    customName: String?,
    kind: CaptureOutputKind,
    date: Date = Date(),
    defaults: UserDefaults = .standard
  ) -> String {
    if let customName {
      let sanitizedCustomName = sanitizeBaseName(customName)
      if !sanitizedCustomName.isEmpty {
        return sanitizedCustomName
      }
    }

    let template = resolvedTemplate(for: kind, defaults: defaults)
    let parsed = parseTemplate(template, kind: kind, date: date)
    let sanitizedParsed = sanitizeBaseName(parsed)
    if !sanitizedParsed.isEmpty {
      return sanitizedParsed
    }

    return fallbackName(for: kind, date: date)
  }

  static func resolvedTemplate(for kind: CaptureOutputKind, defaults: UserDefaults = .standard) -> String {
    guard let raw = defaults.string(forKey: kind.templatePreferenceKey) else {
      return kind.defaultTemplate
    }

    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? kind.defaultTemplate : trimmed
  }

  static func makeUniqueFileURL(in directory: URL, baseName: String, fileExtension: String) -> URL {
    var candidate = directory.appendingPathComponent("\(baseName).\(fileExtension)")
    var suffix = 2

    while FileManager.default.fileExists(atPath: candidate.path) {
      candidate = directory.appendingPathComponent("\(baseName)_\(suffix).\(fileExtension)")
      suffix += 1
    }

    return candidate
  }

  private static func parseTemplate(_ template: String, kind: CaptureOutputKind, date: Date) -> String {
    var resolved = template
    let replacements: [String: String] = [
      "{type}": kind.typeTokenValue,
      "{date}": format(date, style: "yyyy-MM-dd"),
      "{time}": format(date, style: "HH-mm-ss"),
      "{datetime}": format(date, style: "yyyy-MM-dd_HH-mm-ss"),
      "{ms}": format(date, style: "SSS"),
      "{timestamp}": String(Int(date.timeIntervalSince1970)),
    ]

    for (token, value) in replacements {
      resolved = resolved.replacingOccurrences(of: token, with: value)
    }

    return resolved
  }

  private static func sanitizeBaseName(_ value: String) -> String {
    var sanitized = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !sanitized.isEmpty else { return "" }

    sanitized = sanitized.components(separatedBy: invalidFilenameCharacters).joined(separator: "_")
    sanitized = sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    sanitized = sanitized.replacingOccurrences(of: "_{2,}", with: "_", options: .regularExpression)

    let pathExtension = (sanitized as NSString).pathExtension.lowercased()
    if knownExtensions.contains(pathExtension) {
      sanitized = (sanitized as NSString).deletingPathExtension
    }

    sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
    return sanitized
  }

  private static func format(_ date: Date, style: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = style
    return formatter.string(from: date)
  }

  private static func fallbackName(for kind: CaptureOutputKind, date: Date) -> String {
    switch kind {
    case .screenshot:
      return "LocalShot_\(format(date, style: "yyyy-MM-dd_HH-mm-ss-SSS"))"
    case .recording:
      return "LocalShot_Recording_\(format(date, style: "yyyy-MM-dd_HH-mm-ss"))"
    }
  }
}
