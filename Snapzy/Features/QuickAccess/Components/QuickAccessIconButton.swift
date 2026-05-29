//
//  QuickAccessIconButton.swift
//  Snapzy
//
//  Reusable icon button with hover effect and cursor state for quick access cards
//

import AppKit
import SwiftUI

enum QuickAccessTooltipConfiguration {
  static let displayDelayNanoseconds: UInt64 = 2_000_000_000
}

enum QuickAccessTooltipPlacement {
  case top
  case bottom
  case leading
  case trailing
}

private struct QuickAccessTooltipModifier: ViewModifier {
  let text: String?
  let placement: QuickAccessTooltipPlacement

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isPresented = false
  @State private var presentationTask: Task<Void, Never>?

  func body(content: Content) -> some View {
    content
      .overlay {
        GeometryReader { proxy in
          if let text,
             !text.isEmpty,
             isPresented {
            tooltipOverlay(text, hostSize: proxy.size)
              .allowsHitTesting(false)
              .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
              .zIndex(10)
          }
        }
      }
      .onHover { isHovering in
        updatePresentation(isHovering: isHovering)
      }
      .onDisappear {
        presentationTask?.cancel()
      }
  }

  private func updatePresentation(isHovering: Bool) {
    presentationTask?.cancel()

    guard isHovering, text?.isEmpty == false else {
      withAnimation(reduceMotion ? nil : .easeOut(duration: 0.1)) {
        isPresented = false
      }
      return
    }

    presentationTask = Task { @MainActor in
      try? await Task.sleep(nanoseconds: QuickAccessTooltipConfiguration.displayDelayNanoseconds)
      guard !Task.isCancelled else { return }
      withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) {
        isPresented = true
      }
    }
  }

  @ViewBuilder
  private func tooltipOverlay(_ text: String, hostSize: CGSize) -> some View {
    switch placement {
    case .trailing:
      HStack(spacing: 8) {
        Color.clear.frame(width: hostSize.width, height: hostSize.height)
        tooltipBubble(text)
      }
      .fixedSize(horizontal: true, vertical: true)
      .frame(width: hostSize.width, height: hostSize.height, alignment: .leading)
    case .leading:
      HStack(spacing: 8) {
        tooltipBubble(text)
        Color.clear.frame(width: hostSize.width, height: hostSize.height)
      }
      .fixedSize(horizontal: true, vertical: true)
      .frame(width: hostSize.width, height: hostSize.height, alignment: .trailing)
    case .bottom:
      VStack(spacing: 8) {
        Color.clear.frame(width: hostSize.width, height: hostSize.height)
        tooltipBubble(text)
      }
      .fixedSize(horizontal: true, vertical: true)
      .frame(width: hostSize.width, height: hostSize.height, alignment: .top)
    case .top:
      VStack(spacing: 8) {
        tooltipBubble(text)
        Color.clear.frame(width: hostSize.width, height: hostSize.height)
      }
      .fixedSize(horizontal: true, vertical: true)
      .frame(width: hostSize.width, height: hostSize.height, alignment: .bottom)
    }
  }

  private func tooltipBubble(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 11, weight: .semibold))
      .lineLimit(1)
      .foregroundStyle(.white)
      .padding(.horizontal, 9)
      .padding(.vertical, 5)
      .background(
        Capsule(style: .continuous)
          .fill(Color.black.opacity(0.78))
      )
      .overlay(
        Capsule(style: .continuous)
          .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 3)
      .fixedSize(horizontal: true, vertical: false)
  }
}

extension View {
  func quickAccessTooltip(
    _ text: String?,
    placement: QuickAccessTooltipPlacement = .top
  ) -> some View {
    modifier(QuickAccessTooltipModifier(text: text, placement: placement))
  }
}

/// Icon button with hover effect and pointer cursor for card action buttons
struct QuickAccessIconButton: View {
  let icon: String
  let action: () -> Void
  var helpText: String? = nil
  var tooltipPlacement: QuickAccessTooltipPlacement = .top

  @Environment(\.isEnabled) private var isEnabled
  @State private var isHovering = false
  @State private var isPressed = false

  var body: some View {
    Button(action: {
      guard isEnabled else { return }
      // Immediate visual feedback before action
      withAnimation(.easeOut(duration: 0.05)) {
        isPressed = true
      }
      // Execute action immediately
      action()
      // Reset press state
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        isPressed = false
      }
    }) {
      Image(systemName: icon)
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.white.opacity(isEnabled ? 1 : 0.7))
        .frame(width: 20, height: 20)
        .background(
          Circle()
            .fill(buttonBackgroundColor)
        )
        .scaleEffect(isPressed ? 0.85 : 1.0)
    }
    .buttonStyle(.plain)
    .quickAccessTooltip(helpText, placement: tooltipPlacement)
    .onHover { hovering in
      guard isEnabled else {
        isHovering = false
        NSCursor.arrow.set()
        return
      }
      withAnimation(.easeInOut(duration: 0.1)) {
        isHovering = hovering
      }
      if hovering {
        NSCursor.pointingHand.set()
      } else {
        NSCursor.arrow.set()
      }
    }
  }

  private var buttonBackgroundColor: Color {
    if !isEnabled {
      return Color.black.opacity(0.4)
    } else if isPressed {
      return Color.white.opacity(0.5)
    } else if isHovering {
      return Color.white.opacity(0.35)
    } else {
      return Color.black.opacity(0.6)
    }
  }
}
