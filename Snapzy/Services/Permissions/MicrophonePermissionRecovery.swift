//
//  MicrophonePermissionRecovery.swift
//  Snapzy
//
//  Shared microphone permission recovery policy for onboarding and settings.
//

import AVFoundation

enum MicrophonePermissionRecoveryAction: Equatable {
  case requestSystemPrompt
  case openSystemSettings
}

enum MicrophonePermissionRecovery {
  static func isGranted(_ status: AVAuthorizationStatus) -> Bool {
    status == .authorized
  }

  static func action(for status: AVAuthorizationStatus) -> MicrophonePermissionRecoveryAction {
    switch status {
    case .notDetermined:
      return .requestSystemPrompt
    case .authorized, .denied, .restricted:
      return .openSystemSettings
    @unknown default:
      return .openSystemSettings
    }
  }

  static func actionTitle(
    for status: AVAuthorizationStatus,
    grantAccessTitle: String,
    openSettingsTitle: String
  ) -> String {
    switch action(for: status) {
    case .requestSystemPrompt:
      return grantAccessTitle
    case .openSystemSettings:
      return openSettingsTitle
    }
  }
}
