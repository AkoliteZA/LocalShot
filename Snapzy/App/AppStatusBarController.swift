//
//  AppStatusBarController.swift
//  Snapzy
//
//  Manages the NSStatusItem for menu-driven capture actions and live recording status.
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class AppStatusBarController: ObservableObject {

  static let shared = AppStatusBarController()

  // MARK: - Properties

  private var statusItem: NSStatusItem?
  private var cancellables = Set<AnyCancellable>()
  private let recorder = ScreenRecordingManager.shared
  private lazy var idleStatusImage = makeIdleStatusImage()
  private var menu: NSMenu?

  // Dependencies injected after setup
  private var viewModel: ScreenCaptureViewModel?
  // Track if we elevated activation policy for Settings window
  private var didElevateForSettings = false
  private var trackedPreferencesWindow: NSWindow?
  private var trackedPreferencesExcludedWindowID: CGWindowID?

  // Processing indicator (OCR, etc.)
  private var processingSpinner: NSProgressIndicator?
  private(set) var isProcessing = false

  private init() {}

  // MARK: - Public API

  /// Setup the status bar item with required dependencies
  func setup(viewModel: ScreenCaptureViewModel) {
    self.viewModel = viewModel

    setupStatusItem()
    buildMenu()
    observeRecordingState()

    // Pre-allocate area selection windows for instant activation (<150ms)
    AreaSelectionController.shared.prepareWindowPool()
    DiagnosticLogger.shared.log(
      .info,
      .ui,
      "Status bar item initialized",
      context: ["previousCrashPrompt": "false"]
    )
  }

  func stopRecording() {
    RecordingCoordinator.shared.stopFromStatusItem()
  }

  /// Show or hide a processing spinner on the menu bar icon (e.g. during OCR).
  /// The spinner runs on Core Animation so it stays animated even when the main thread is briefly busy.
  func setProcessing(_ active: Bool) {
    guard active != isProcessing else { return }
    isProcessing = active

    guard let button = statusItem?.button else { return }

    if active {
      // Swap to a transparent placeholder of the same size to preserve layout
      if let icon = button.image {
        let placeholder = NSImage(size: icon.size)
        placeholder.isTemplate = true
        button.image = placeholder
      }

      // Create a spinning indicator sized to match the icon
      let size: CGFloat = 16
      let spinner = NSProgressIndicator()
      spinner.style = .spinning
      spinner.controlSize = .small
      spinner.isIndeterminate = true
      spinner.isDisplayedWhenStopped = false
      spinner.frame = CGRect(
        x: (button.bounds.width - size) / 2,
        y: (button.bounds.height - size) / 2,
        width: size,
        height: size
      )
      spinner.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
      button.addSubview(spinner)
      spinner.startAnimation(nil)
      processingSpinner = spinner

      DiagnosticLogger.shared.log(.debug, .ui, "Status bar processing indicator started")
    } else {
      processingSpinner?.stopAnimation(nil)
      processingSpinner?.removeFromSuperview()
      processingSpinner = nil

      // Restore original icon
      button.image = idleStatusImage
      DiagnosticLogger.shared.log(.debug, .ui, "Status bar processing indicator stopped")
    }
  }

  // MARK: - Private Setup

  private func setupStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    if let button = statusItem?.button {
      button.imagePosition = .imageLeading
      button.target = self
      button.action = #selector(statusBarButtonClicked(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
      renderStatusItem()
    }
  }

  @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
    guard let event = NSApp.currentEvent else { return }
    switch event.type {
    case .leftMouseUp, .rightMouseUp:
      DiagnosticLogger.shared.log(
        .debug,
        .ui,
        "Status bar menu opened",
        context: ["event": event.type == .leftMouseUp ? "leftMouseUp" : "rightMouseUp"]
      )
      showMenu()
    default:
      break
    }
  }

  private func showMenu() {
    guard let button = statusItem?.button else { return }
    buildMenu()  // Rebuild to update state
    statusItem?.menu = menu
    button.performClick(nil)
    statusItem?.menu = nil  // Reset to allow custom click handling
  }

  // MARK: - State Observation

  private func observeRecordingState() {
    recorder.$state
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.renderStatusItem()
        self?.syncTrackedPreferencesWindowExclusion()
      }
      .store(in: &cancellables)

    recorder.$elapsedSeconds
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.renderStatusItem()
      }
      .store(in: &cancellables)
  }

  private func renderStatusItem() {
    guard let button = statusItem?.button else { return }
    button.image = idleStatusImage
    button.contentTintColor = nil
    button.attributedTitle = statusItemAttributedTitle(for: recorder.state)
    button.toolTip = statusItemTooltip(for: recorder.state)
  }

  private func statusItemAttributedTitle(for state: RecordingState) -> NSAttributedString {
    let title: String
    switch state {
    case .recording:
      title = recorder.formattedDuration
    case .paused:
      title = "|| \(recorder.formattedDuration)"
    case .idle, .preparing, .stopping:
      title = ""
    }

    guard !title.isEmpty else {
      return NSAttributedString(string: "")
    }

    let menuBarFont = NSFont.menuBarFont(ofSize: 0)
    let monospacedDigitsFont = NSFont.monospacedDigitSystemFont(
      ofSize: menuBarFont.pointSize,
      weight: .regular
    )

    return NSAttributedString(
      string: title,
      attributes: [
        .font: monospacedDigitsFont,
        .foregroundColor: NSColor.labelColor,
      ]
    )
  }

  private func statusItemTooltip(for state: RecordingState) -> String {
    switch state {
    case .recording:
      return "\(L10n.RecordingToolbar.recordingInProgress) (\(recorder.formattedDuration))"
    case .paused:
      return "\(L10n.RecordingToolbar.recordingPaused) (\(recorder.formattedDuration))"
    case .preparing:
      return LocalShotBrand.appName
    case .stopping:
      return LocalShotBrand.appName
    case .idle:
      return LocalShotBrand.appName
    }
  }

  private func makeIdleStatusImage() -> NSImage? {
    guard let appIcon = NSImage(named: "MenubarIcon") else { return nil }

    let size = NSSize(width: 18, height: 18)
    let resizedIcon = NSImage(size: size)
    resizedIcon.lockFocus()
    appIcon.draw(
      in: NSRect(origin: .zero, size: size),
      from: NSRect(origin: .zero, size: appIcon.size),
      operation: .copy,
      fraction: 1.0
    )
    resizedIcon.unlockFocus()
    // Template images let AppKit adapt the glyph color to the current menu bar material.
    resizedIcon.isTemplate = true
    return resizedIcon
  }

  // MARK: - Menu Building

  private func buildMenu() {
    menu = NSMenu()
    menu?.autoenablesItems = false

    guard let viewModel = viewModel else {
      DiagnosticLogger.shared.log(.warning, .ui, "Status bar menu requested before view model setup")
      return
    }
    let shortcutManager = KeyboardShortcutManager.shared

    let headerItem = NSMenuItem(title: MenuBarCaptureMenuModel.headerDisplayTitle, action: nil, keyEquivalent: "")
    headerItem.image = NSApp.applicationIconImage
    headerItem.isEnabled = false
    menu?.addItem(headerItem)
    menu?.addItem(NSMenuItem.separator())

    // Recording status indicator (when recording)
    if recorder.state == .recording || recorder.state == .paused {
      let stopItem = NSMenuItem(
        title: L10n.Menu.stopRecording(recorder.formattedDuration),
        action: #selector(stopRecordingAction),
        keyEquivalent: ""
      )
      stopItem.target = self
      stopItem.image = NSImage(systemSymbolName: "stop.fill", accessibilityDescription: nil)
      stopItem.isEnabled = true
      menu?.addItem(stopItem)

      let pauseResumeItem = NSMenuItem(
        title: recorder.isPaused ? L10n.RecordingToolbar.resumeRecording : L10n.RecordingToolbar.pauseRecording,
        action: #selector(togglePauseRecordingAction),
        keyEquivalent: ""
      )
      pauseResumeItem.target = self
      pauseResumeItem.image = NSImage(
        systemSymbolName: recorder.isPaused ? "play.fill" : "pause.fill",
        accessibilityDescription: nil
      )
      pauseResumeItem.isEnabled = recorder.state == .recording || recorder.state == .paused
      menu?.addItem(pauseResumeItem)

      menu?.addItem(NSMenuItem.separator())
    }

    let menuSections = MenuBarCaptureMenuModel.sections(
      hasScreenCapturePermission: viewModel.hasPermission,
      hasPreviousCaptureArea: viewModel.hasPreviousCaptureArea,
      isRecordingActive: recorder.isActive,
      isScrollingCaptureActive: ScrollingCaptureCoordinator.shared.isActive
    )
    for (index, section) in menuSections.enumerated() {
      if index > 0 {
        menu?.addItem(NSMenuItem.separator())
      }
      addSectionHeader(section.title)
      for item in section.items {
        addConfiguredMenuItem(item, using: shortcutManager)
      }
    }

    // Permission (if not granted)
    if !viewModel.hasPermission {
      menu?.addItem(NSMenuItem.separator())
      let permissionItem = NSMenuItem(
        title: L10n.Menu.grantPermission,
        action: #selector(grantPermissionAction),
        keyEquivalent: ""
      )
      permissionItem.target = self
      permissionItem.image = NSImage(
        systemSymbolName: "lock.shield", accessibilityDescription: nil)
      permissionItem.isEnabled = true
      menu?.addItem(permissionItem)
      menu?.addItem(NSMenuItem.separator())
    }

    menu?.addItem(NSMenuItem.separator())

    let saveLocationItem = NSMenuItem(
      title: MenuSaveLocationFormatter.title(
        for: SandboxFileAccessManager.shared.exportLocationPath
      ),
      action: nil,
      keyEquivalent: ""
    )
    saveLocationItem.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
    saveLocationItem.isEnabled = false
    menu?.addItem(saveLocationItem)

    // Quit
    let quitItem = NSMenuItem(
      title: L10n.Menu.quitSnapzy,
      action: #selector(quitAction),
      keyEquivalent: "q"
    )
    quitItem.keyEquivalentModifierMask = .command
    quitItem.target = self
    quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
    quitItem.isEnabled = true
    menu?.addItem(quitItem)
  }

  private func addSectionHeader(_ title: String) {
    let item = NSMenuItem(title: title.uppercased(), action: nil, keyEquivalent: "")
    item.isEnabled = false
    menu?.addItem(item)
  }

  private func addConfiguredMenuItem(
    _ item: MenuBarCaptureMenuItem,
    using shortcutManager: KeyboardShortcutManager
  ) {
    let menuItem = NSMenuItem(
      title: item.title,
      action: selector(for: item.id),
      keyEquivalent: ""
    )

    configureShortcut(for: menuItem, itemID: item.id, using: shortcutManager)
    menuItem.target = self
    menuItem.image = NSImage(systemSymbolName: item.systemImage, accessibilityDescription: nil)
    menuItem.isEnabled = item.isEnabled
    menu?.addItem(menuItem)
  }

  private func configureShortcut(
    for menuItem: NSMenuItem,
    itemID: MenuBarCaptureMenuItemID,
    using shortcutManager: KeyboardShortcutManager
  ) {
    switch itemID {
    case .captureArea:
      applyConfiguredShortcut(menuItem, for: .area, using: shortcutManager)
    case .captureWindow:
      configureOverlayMenuItem(
        menuItem,
        base: "Capture Window",
        shortcut: CaptureOverlayShortcutSettings.applicationCaptureShortcut,
        parentKind: .area,
        using: shortcutManager
      )
    case .captureFullScreen:
      applyConfiguredShortcut(menuItem, for: .fullscreen, using: shortcutManager)
    case .scrollingCapture:
      applyConfiguredShortcut(menuItem, for: .scrollingCapture, using: shortcutManager)
    case .recordArea:
      applyConfiguredShortcut(menuItem, for: .recording, using: shortcutManager)
    case .recordFullScreen:
      configureOverlayMenuItem(
        menuItem,
        base: "Record Full Screen",
        shortcut: CaptureOverlayShortcutSettings.recordingApplicationCaptureShortcut,
        parentKind: .recording,
        using: shortcutManager
      )
    case .history:
      applyConfiguredShortcut(menuItem, for: .history, using: shortcutManager)
    case .settings:
      menuItem.keyEquivalent = ","
      menuItem.keyEquivalentModifierMask = .command
    case .capturePreviousArea, .gifRecording:
      menuItem.keyEquivalent = ""
      menuItem.keyEquivalentModifierMask = []
    }
  }

  private func selector(for itemID: MenuBarCaptureMenuItemID) -> Selector {
    switch itemID {
    case .captureArea:
      return #selector(captureAreaAction)
    case .captureWindow:
      return #selector(captureApplicationAction)
    case .captureFullScreen:
      return #selector(captureFullscreenAction)
    case .capturePreviousArea:
      return #selector(capturePreviousAreaAction)
    case .scrollingCapture:
      return #selector(captureScrollingAction)
    case .recordArea:
      return #selector(recordScreenAction)
    case .recordFullScreen:
      return #selector(recordFullscreenAction)
    case .gifRecording:
      return #selector(recordGIFAction)
    case .history:
      return #selector(openHistoryAction)
    case .settings:
      return #selector(openPreferencesAction)
    }
  }

  // MARK: - Menu Actions

  @objc private func stopRecordingAction() {
    logMenuAction("stopRecording", context: ["state": "\(recorder.state)"])
    stopRecording()
  }

  @objc private func togglePauseRecordingAction() {
    logMenuAction("togglePauseRecording", context: ["state": "\(recorder.state)"])
    recorder.togglePause()
  }

  @objc private func captureAreaAction() {
    logMenuAction("captureArea")
    viewModel?.captureArea()
  }

  @objc private func capturePreviousAreaAction() {
    logMenuAction("capturePreviousArea")
    viewModel?.capturePreviousArea()
  }

  @objc private func captureAreaAnnotateAction() {
    logMenuAction("captureAreaAnnotate")
    viewModel?.captureAreaAnnotate()
  }

  @objc private func captureApplicationAction() {
    logMenuAction("captureApplication")
    viewModel?.captureApplication()
  }

  @objc private func captureFullscreenAction() {
    logMenuAction("captureFullscreen")
    viewModel?.captureFullscreen()
  }

  @objc private func captureScrollingAction() {
    logMenuAction("captureScrolling")
    viewModel?.captureScrolling()
  }

  @objc private func captureOCRAction() {
    logMenuAction("captureOCR")
    viewModel?.captureOCR()
  }

  @objc private func captureObjectCutoutAction() {
    logMenuAction("captureObjectCutout")
    viewModel?.captureObjectCutout()
  }

  @objc private func recordScreenAction() {
    logMenuAction("recordScreen")
    viewModel?.startRecordingFlow()
  }

  @objc private func recordApplicationAction() {
    logMenuAction("recordApplication")
    viewModel?.startApplicationRecordingFlow()
  }

  @objc private func recordFullscreenAction() {
    logMenuAction("recordFullscreen")
    viewModel?.startFullscreenRecordingFlow()
  }

  @objc private func recordGIFAction() {
    logMenuAction("recordGIF")
    UserDefaults.standard.set(RecordingOutputMode.gif.rawValue, forKey: PreferencesKeys.recordingOutputMode)
    viewModel?.startRecordingFlow()
  }

  @objc private func openAnnotateAction() {
    logMenuAction("openAnnotate")
    AnnotateManager.shared.openEmptyAnnotation()
  }

  @objc private func editVideoAction() {
    logMenuAction("editVideo")
    guard LocalShotV1Policy.complexVideoEditorEntryPointsEnabled else { return }
    VideoEditorManager.shared.openEmptyEditor()
  }

  @objc private func openCloudUploadsAction() {
    logMenuAction("openCloudUploadsDisabledForV1")
  }

  @objc private func openHistoryAction() {
    logMenuAction("openHistory")
    HistoryFloatingManager.shared.toggle()
  }

  @objc private func showShortcutListAction() {
    logMenuAction("showShortcutList")
    ShortcutOverlayManager.shared.toggle()
  }

  @objc private func grantPermissionAction() {
    logMenuAction("grantPermission")
    viewModel?.requestPermission()
  }

  @objc private func checkForUpdatesAction() {
    logMenuAction("checkForUpdatesDisabledForV1")
  }

  @objc private func openPreferencesAction() {
    logMenuAction("openPreferences")
    openPreferencesWindow()
  }

  func openPreferencesWindow(tab: PreferencesTab? = nil) {
    if let tab {
      PreferencesNavigationState.shared.selectedTab = tab
    }
    DiagnosticLogger.shared.log(
      .info,
      .preferences,
      "Preferences window requested",
      context: ["tab": tab.map { "\($0)" } ?? "current"]
    )
    presentPreferencesWindow()
  }

  private func presentPreferencesWindow() {
    if let trackedPreferencesWindow, trackedPreferencesWindow.isVisible {
      NSApp.setActivationPolicy(.regular)
      didElevateForSettings = true
      NSApp.activate(ignoringOtherApps: true)
      trackedPreferencesWindow.makeKeyAndOrderFront(nil)
      syncTrackedPreferencesWindowExclusion()
      return
    }

    // Elevate to regular app so LocalShot can present a standard Settings window.
    if !didElevateForSettings {
      NSApp.setActivationPolicy(.regular)
      didElevateForSettings = true
      DiagnosticLogger.shared.log(.debug, .ui, "Activation policy elevated for preferences window")

      // Observe when Settings window closes to revert policy
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(windowDidClose(_:)),
        name: NSWindow.willCloseNotification,
        object: nil
      )
    }

    let contentView = PreferencesView()
      .preferredColorScheme(ThemeManager.shared.systemAppearance)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 980, height: 720),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "\(LocalShotBrand.appName) Settings"
    window.contentViewController = NSHostingController(rootView: contentView)
    window.isReleasedWhenClosed = false
    window.setFrameAutosaveName("\(LocalShotBrand.appName)SettingsWindow")
    window.center()

    trackedPreferencesWindow = window
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    syncTrackedPreferencesWindowExclusion()
  }

  @objc private func windowDidClose(_ notification: Notification) {
    if let window = notification.object as? NSWindow, trackedPreferencesWindow === window {
      DiagnosticLogger.shared.log(.debug, .preferences, "Tracked preferences window closed")
      trackedPreferencesWindow = nil
      removeTrackedPreferencesWindowExclusion()
    }

    // Check if any visible windows remain (excluding status bar popover)
    let visibleWindows = NSApp.windows.filter { window in
      window.isVisible &&
      window.className != "NSStatusBarWindow" &&
      window.level == .normal
    }

    // If no visible windows, revert to accessory (menu bar only) mode
    if visibleWindows.isEmpty && didElevateForSettings {
      NSApp.setActivationPolicy(.accessory)
      didElevateForSettings = false
      DiagnosticLogger.shared.log(.debug, .ui, "Activation policy restored after preferences closed")
      NotificationCenter.default.removeObserver(
        self,
        name: NSWindow.willCloseNotification,
        object: nil
      )
    }
  }

  @objc private func quitAction() {
    logMenuAction("quit")
    NSApp.terminate(nil)
  }

  private func logMenuAction(_ action: String, context: [String: String]? = nil) {
    DiagnosticLogger.shared.log(
      .info,
      .action,
      "Menu action invoked",
      context: {
        var values = context ?? [:]
        values["action"] = action
        return values
      }()
    )
  }

  private func applyConfiguredShortcut(
    _ item: NSMenuItem,
    for kind: GlobalShortcutKind,
    using manager: KeyboardShortcutManager
  ) {
    guard manager.isShortcutEnabled(for: kind) else {
      item.keyEquivalent = ""
      item.keyEquivalentModifierMask = []
      return
    }

    let config = manager.shortcut(for: kind)
    guard let config, let keyEquivalent = config.menuKeyEquivalent else {
      item.keyEquivalent = ""
      item.keyEquivalentModifierMask = []
      return
    }

    item.keyEquivalent = keyEquivalent
    item.keyEquivalentModifierMask = config.menuModifierFlags
  }

  private func configureOverlayMenuItem(
    _ item: NSMenuItem,
    base: String,
    shortcut: CaptureOverlayShortcut?,
    parentKind: GlobalShortcutKind,
    using manager: KeyboardShortcutManager
  ) {
    guard let shortcut else {
      item.title = base
      item.keyEquivalent = ""
      item.keyEquivalentModifierMask = []
      return
    }

    if shortcut.isIndependent {
      item.title = base
      guard let config = shortcut.independentShortcutConfig,
            let keyEquivalent = config.menuKeyEquivalent else {
        item.keyEquivalent = ""
        item.keyEquivalentModifierMask = []
        return
      }

      item.keyEquivalent = keyEquivalent
      item.keyEquivalentModifierMask = config.menuModifierFlags
      return
    }

    let childDisplay = CaptureOverlayShortcut.inlineDisplay(parts: shortcut.displayParts)
    guard manager.isShortcutEnabled(for: parentKind),
          let parentConfig = manager.shortcut(for: parentKind),
          let parentKeyEquivalent = parentConfig.menuKeyEquivalent else {
      item.title = base
      item.keyEquivalent = ""
      item.keyEquivalentModifierMask = []
      return
    }

    item.title = "\(base) \(childDisplay)"
    item.keyEquivalent = parentKeyEquivalent
    item.keyEquivalentModifierMask = parentConfig.menuModifierFlags
  }

  private func syncTrackedPreferencesWindowExclusion() {
    guard let trackedPreferencesWindow, trackedPreferencesWindow.isVisible else {
      removeTrackedPreferencesWindowExclusion()
      return
    }

    let windowID = CGWindowID(trackedPreferencesWindow.windowNumber)

    guard recorder.isActive else {
      removeTrackedPreferencesWindowExclusion()
      return
    }

    guard trackedPreferencesExcludedWindowID != windowID else { return }

    let previousWindowID = trackedPreferencesExcludedWindowID
    trackedPreferencesExcludedWindowID = windowID
    DiagnosticLogger.shared.log(
      .debug,
      .recording,
      "Preferences window added to runtime recording exclusion",
      context: ["windowID": "\(windowID)"]
    )

    Task { @MainActor [weak self] in
      guard let self else { return }
      if let previousWindowID, previousWindowID != windowID {
        await self.recorder.removeRuntimeExcludedWindow(windowID: previousWindowID)
      }
      await self.recorder.addRuntimeExcludedWindow(windowID: windowID)
    }
  }

  private func removeTrackedPreferencesWindowExclusion() {
    guard let windowID = trackedPreferencesExcludedWindowID else { return }
    trackedPreferencesExcludedWindowID = nil
    DiagnosticLogger.shared.log(
      .debug,
      .recording,
      "Preferences window removed from runtime recording exclusion",
      context: ["windowID": "\(windowID)"]
    )

    Task { @MainActor [weak self] in
      guard let self else { return }
      await self.recorder.removeRuntimeExcludedWindow(windowID: windowID)
    }
  }
}
