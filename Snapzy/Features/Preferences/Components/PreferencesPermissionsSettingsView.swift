//
//  PermissionsSettingsView.swift
//  Snapzy
//
//  Permissions status tab showing system permission states and settings links
//

import AppKit
import ApplicationServices
import AVFoundation
import SwiftUI

enum PermissionsRecoveryNotePolicy {
  static func shouldShow(
    screenRecordingGranted: Bool,
    saveFolderGranted: Bool,
    microphoneGranted: Bool,
    buildIdentityNeedsAttention: Bool
  ) -> Bool {
    !screenRecordingGranted || !saveFolderGranted || !microphoneGranted || buildIdentityNeedsAttention
  }
}

struct PermissionsSettingsView: View {
  @ObservedObject private var screenCaptureManager = ScreenCaptureManager.shared
  @ObservedObject private var identityManager = AppIdentityManager.shared
  @State private var microphoneAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
  @State private var microphoneGranted = false
  @State private var accessibilityGranted = false
  @State private var saveFolderGranted = false
  @State private var isChecking = false
  @State private var hasAppeared = false

  private let fileAccessManager = SandboxFileAccessManager.shared

  // System Settings URLs
  private let screenRecordingURL =
    "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
  private let microphoneURL =
    "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
  private let accessibilityURL =
    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

  var body: some View {
    Form {
      Section(L10n.Preferences.permissionsTab) {
        Text(L10n.PreferencesPermissions.intro)
          .font(.caption)
          .foregroundColor(.secondary)

        permissionRow(
          icon: "rectangle.inset.filled.and.person.filled",
          name: L10n.Onboarding.screenRecording,
          description: screenRecordingDescription,
          statusLabel: screenRecordingStatusLabel,
          statusIcon: screenRecordingStatusIcon,
          statusColor: screenRecordingStatusColor,
          isRequired: true,
          action: {
            openSystemSettings(screenRecordingURL)
          }
        )

        if shouldShowPermissionRecoveryNote {
          permissionRecoveryNote
        }

        permissionRow(
          icon: "folder.fill",
          name: L10n.Onboarding.saveFolder,
          description: L10n.Onboarding.requiredForCaptures,
          statusLabel: saveFolderGranted ? L10n.PermissionRow.granted : L10n.Common.notGranted,
          statusIcon: saveFolderGranted ? "checkmark.circle.fill" : "xmark.circle.fill",
          statusColor: saveFolderGranted ? .green : .orange,
          isRequired: true,
          buttonTitle: saveFolderGranted ? L10n.FileAccess.chooseFolderPrompt : L10n.FileAccess.grantAccessPrompt,
          action: {
            requestSaveFolderPermission()
          }
        )

        permissionRow(
          icon: "mic.fill",
          name: L10n.Onboarding.microphone,
          description: L10n.Onboarding.optionalForVoiceRecording,
          statusLabel: microphoneGranted ? L10n.PermissionRow.granted : L10n.Common.notGranted,
          statusIcon: microphoneGranted ? "checkmark.circle.fill" : "xmark.circle.fill",
          statusColor: microphoneGranted ? .green : .orange,
          isRequired: false,
          buttonTitle: microphoneActionTitle,
          action: {
            requestMicrophonePermission()
          }
        )

        permissionRow(
          icon: "hand.raised.fill",
          name: L10n.Onboarding.accessibility,
          description: L10n.Onboarding.optionalForGlobalShortcuts,
          statusLabel: accessibilityGranted ? L10n.PermissionRow.granted : L10n.Common.notGranted,
          statusIcon: accessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill",
          statusColor: accessibilityGranted ? .green : .orange,
          isRequired: false,
          buttonTitle: accessibilityActionTitle,
          action: {
            if accessibilityGranted {
              openSystemSettings(accessibilityURL)
            } else {
              requestAccessibilityPermission()
            }
          }
        )

        if identityManager.health.needsAttention {
          VStack(alignment: .leading, spacing: 6) {
            Text(L10n.Onboarding.buildIdentityNeedsAttention)
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.orange)

            ForEach(identityManager.health.attentionMessages, id: \.self) { message in
              Text("• \(message)")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .padding(.vertical, 4)
        }

        HStack {
          Spacer()
          Button {
            checkAllPermissions()
          } label: {
            HStack(spacing: 4) {
              if isChecking {
                ProgressView()
                  .controlSize(.small)
              } else {
                Image(systemName: "arrow.clockwise")
              }
              Text(L10n.Onboarding.refreshStatus)
            }
          }
          .disabled(isChecking)
        }
        .padding(.top, 4)
      }
    }
    .formStyle(.grouped)
    .onAppear {
      hasAppeared = true
      checkAllPermissions()
    }
    .onDisappear {
      hasAppeared = false
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
      guard hasAppeared else { return }
      checkAllPermissions()
    }
  }

  private var permissionRecoveryNote: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "info.circle.fill")
        .foregroundColor(.teal)
        .padding(.top, 1)

      VStack(alignment: .leading, spacing: 3) {
        Text(L10n.PreferencesPermissions.localBuildPermissionNoteTitle)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
        Text(L10n.PreferencesPermissions.localBuildPermissionNoteDescription)
          .font(.caption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.vertical, 6)
  }

  private var shouldShowPermissionRecoveryNote: Bool {
    PermissionsRecoveryNotePolicy.shouldShow(
      screenRecordingGranted: screenCaptureManager.permissionStatus == .granted,
      saveFolderGranted: saveFolderGranted,
      microphoneGranted: microphoneGranted,
      buildIdentityNeedsAttention: identityManager.health.needsAttention
    )
  }

  // MARK: - Permission Row Component

  @ViewBuilder
  private func permissionRow(
    icon: String,
    name: String,
    description: String,
    statusLabel: String,
    statusIcon: String,
    statusColor: Color,
    isRequired: Bool,
    buttonTitle: String = L10n.Common.openSettings,
    action: @escaping () -> Void
  ) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.secondary)
        .frame(width: 28)

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(name)
            .fontWeight(.medium)
          if isRequired {
            StatusBadge(
              label: L10n.PermissionRow.required,
              systemImage: "exclamationmark.circle.fill",
              tint: .orange
            )
            .help(L10n.PermissionRow.required)
          }
        }
        Text(description)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      StatusBadge(
        label: statusLabel,
        systemImage: statusIcon,
        tint: statusColor
      )

      Button(buttonTitle) {
        action()
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
    }
    .padding(.vertical, 4)
  }

  // MARK: - Permission Checking

  private func checkAllPermissions() {
    isChecking = true

    checkMicrophonePermission()
    checkAccessibilityPermission()
    checkSaveFolderPermission()

    Task {
      await checkScreenRecordingPermission()
      await MainActor.run {
        isChecking = false
      }
    }
  }

  private func checkScreenRecordingPermission() async {
    AppIdentityManager.shared.refresh()
    await screenCaptureManager.checkPermission()
  }

  private func checkMicrophonePermission() {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    microphoneAuthorizationStatus = status
    microphoneGranted = MicrophonePermissionRecovery.isGranted(status)
  }

  private func checkAccessibilityPermission() {
    accessibilityGranted = AXIsProcessTrusted()
  }

  private func checkSaveFolderPermission() {
    fileAccessManager.ensureExportLocationInitialized()
    saveFolderGranted = fileAccessManager.hasPersistedExportPermission
  }

  private func requestSaveFolderPermission() {
    _ = fileAccessManager.chooseExportDirectory(
      message: L10n.FileAccess.chooseCapturesFolderMessage,
      prompt: L10n.FileAccess.grantAccessPrompt,
      directoryURL: fileAccessManager.resolvedExportDirectoryURL()
    )
    checkSaveFolderPermission()
  }

  private func requestMicrophonePermission() {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    switch MicrophonePermissionRecovery.action(for: status) {
    case .requestSystemPrompt:
      AVCaptureDevice.requestAccess(for: .audio) { granted in
        DispatchQueue.main.async {
          microphoneAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
          microphoneGranted = granted
        }
      }
    case .openSystemSettings:
      openSystemSettings(microphoneURL)
      checkMicrophonePermission()
    }
  }

  private func requestAccessibilityPermission() {
    if AXIsProcessTrusted() {
      accessibilityGranted = true
      return
    }

    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
    openSystemSettings(accessibilityURL)
    checkAccessibilityPermission()
  }

  private var screenRecordingDescription: String {
    switch screenCaptureManager.permissionStatus {
    case .granted:
      return L10n.Onboarding.requiredForCaptures
    case .notGranted:
      return L10n.Onboarding.requiredForCaptures
    case .grantedButUnavailableDueToAppIdentity:
      return L10n.Onboarding.screenRecordingIdentityBlocked
    }
  }

  private var screenRecordingStatusLabel: String {
    switch screenCaptureManager.permissionStatus {
    case .granted:
      return L10n.PermissionRow.granted
    case .notGranted:
      return L10n.Common.notGranted
    case .grantedButUnavailableDueToAppIdentity:
      return L10n.Onboarding.unavailable
    }
  }

  private var screenRecordingStatusIcon: String {
    switch screenCaptureManager.permissionStatus {
    case .granted:
      return "checkmark.circle.fill"
    case .notGranted:
      return "xmark.circle.fill"
    case .grantedButUnavailableDueToAppIdentity:
      return "exclamationmark.triangle.fill"
    }
  }

  private var screenRecordingStatusColor: Color {
    switch screenCaptureManager.permissionStatus {
    case .granted:
      return .green
    case .notGranted, .grantedButUnavailableDueToAppIdentity:
      return .orange
    }
  }

  private var microphoneActionTitle: String {
    MicrophonePermissionRecovery.actionTitle(
      for: microphoneAuthorizationStatus,
      grantAccessTitle: L10n.Onboarding.grantAccess,
      openSettingsTitle: L10n.Common.openSettings
    )
  }

  private var accessibilityActionTitle: String {
    accessibilityGranted ? L10n.Common.openSettings : L10n.Onboarding.grantAccess
  }

  // MARK: - System Settings Navigation

  private func openSystemSettings(_ urlString: String) {
    if let url = URL(string: urlString) {
      NSWorkspace.shared.open(url)
    }
  }
}

#Preview {
  PermissionsSettingsView()
    .frame(width: 600, height: 400)
}
