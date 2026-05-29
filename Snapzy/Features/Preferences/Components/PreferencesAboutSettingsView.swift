//
//  PreferencesAboutSettingsView.swift
//  Snapzy
//
//  Local-only about and attribution tab.
//

import AppKit
import SwiftUI

struct AboutSettingsView: View {
  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    return "\(version) (\(build))"
  }

  var body: some View {
    Form {
      Section {
        HStack(spacing: Spacing.md) {
          Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

          VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: LocalShotBrand.appName)
              .font(.system(size: 26, weight: .semibold, design: .rounded))
            Text(verbatim: "Private local screenshot and recording utility")
              .foregroundColor(.secondary)
            Text(verbatim: "Version \(appVersion)")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
        }
        .padding(.vertical, 8)
      }

      Section("Privacy") {
        privacyRow("checkmark.shield", "Local-only mode")
        privacyRow("icloud.slash", "Cloud upload disabled")
        privacyRow("person.crop.circle.badge.xmark", "No accounts")
        privacyRow("chart.bar.xaxis", "No telemetry")
        privacyRow("arrow.triangle.2.circlepath.circle", "No auto-update checks in v1")
        privacyRow("externaldrive", "Storage: ~/Library/Application Support/LocalShot")
      }

      Section("Acknowledgements") {
        Text(verbatim: "BSD 3-Clause attribution is preserved in the project license and documentation.")
          .font(.callout)
          .foregroundColor(.secondary)
        Text(verbatim: "All captures, recordings, OCR text, thumbnails, and history remain on this Mac by default.")
          .font(.callout)
          .foregroundColor(.secondary)
      }
    }
    .formStyle(.grouped)
  }

  private func privacyRow(_ icon: String, _ title: String) -> some View {
    Label {
      Text(verbatim: title)
    } icon: {
      Image(systemName: icon)
        .foregroundStyle(Color.accentColor)
    }
  }
}

#Preview {
  AboutSettingsView()
    .frame(width: 700, height: 550)
}
