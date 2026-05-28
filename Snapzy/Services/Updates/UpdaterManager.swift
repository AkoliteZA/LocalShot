//
//  UpdaterManager.swift
//  Snapzy
//
//  LocalShot v1 intentionally has no public updater.
//

import Combine
import Foundation

@MainActor
final class UpdaterManager: ObservableObject {
  static let shared = UpdaterManager()

  @Published var automaticallyChecksForUpdates = false
  @Published var automaticallyDownloadsUpdates = false
  @Published private(set) var lastUpdateCheckDate: Date?

  private init() {}

  func checkForUpdates() {
    DiagnosticLogger.shared.log(.info, .update, "Updater disabled for LocalShot v1")
  }
}
