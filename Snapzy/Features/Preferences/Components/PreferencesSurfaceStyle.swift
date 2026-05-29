//
//  PreferencesSurfaceStyle.swift
//  Snapzy
//
//  Neutral settings surfaces that avoid macOS wallpaper tint drift.
//

import AppKit
import SwiftUI

enum PreferencesSurfacePalette {
  static let darkBackground = NSColor(srgbRed: 0.11, green: 0.115, blue: 0.125, alpha: 1)
  static let lightBackground = NSColor(srgbRed: 0.95, green: 0.955, blue: 0.965, alpha: 1)
  static let darkRowBackground = NSColor(srgbRed: 0.155, green: 0.16, blue: 0.17, alpha: 1)
  static let lightRowBackground = NSColor(srgbRed: 0.985, green: 0.987, blue: 0.992, alpha: 1)

  static func backgroundColor(for colorScheme: ColorScheme) -> NSColor {
    colorScheme == .dark ? darkBackground : lightBackground
  }

  static func background(for colorScheme: ColorScheme) -> Color {
    Color(nsColor: backgroundColor(for: colorScheme))
  }

  static func rowBackground(for colorScheme: ColorScheme) -> Color {
    Color(nsColor: colorScheme == .dark ? darkRowBackground : lightRowBackground)
  }
}

private struct PreferencesRootSurfaceModifier: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content
      .tint(.accentColor)
      .background(PreferencesSurfacePalette.background(for: colorScheme).ignoresSafeArea())
  }
}

private struct PreferencesFormSurfaceModifier: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content
      .formStyle(.grouped)
      .scrollContentBackground(.hidden)
      .background(PreferencesSurfacePalette.background(for: colorScheme).ignoresSafeArea())
      .listRowBackground(PreferencesSurfacePalette.rowBackground(for: colorScheme))
      .tint(.accentColor)
  }
}

private struct PreferencesRowSurfaceModifier: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content
      .listRowBackground(PreferencesSurfacePalette.rowBackground(for: colorScheme))
  }
}

extension View {
  func preferencesRootSurface() -> some View {
    modifier(PreferencesRootSurfaceModifier())
  }

  func preferencesFormSurface() -> some View {
    modifier(PreferencesFormSurfaceModifier())
  }

  func preferencesRowSurface() -> some View {
    modifier(PreferencesRowSurfaceModifier())
  }
}
