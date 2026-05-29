# Changelog

All notable LocalShot changes are tracked here.

## [1.20.1] - 2026-05-29

### Added

- LocalShot branding, bundle display name, URL scheme, bundle identifier, app
  support path, and default export path.
- Local-first Quick Access screenshot cards with copy, annotate, OCR, pin,
  delete, drag, dismiss, and tooltip affordances.
- Configurable shortcuts and a setting to make LocalShot the default screenshot
  app for common macOS screenshot shortcuts.
- Local privacy verification and build helper scripts.

### Changed

- Reworked settings styling around the LocalShot blue logo palette and macOS
  light/dark appearances.
- Improved area capture startup by allowing the fast CoreGraphics frozen
  snapshot path when LocalShot's own visible windows have been hidden.
- Kept internal Xcode project and scheme names as `Snapzy` while publishing the
  product as `LocalShot.app`.

### Removed

- Public cloud upload, account, telemetry, crash-report submission, and
  auto-update surfaces from the LocalShot v1 app.

### Attribution

- LocalShot is explicitly a fork of Snapzy by Trong Duong Duc and preserves the
  original BSD 3-Clause License notice.
