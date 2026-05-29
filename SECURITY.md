# Security And Privacy

LocalShot is a local-first macOS utility. Capture, annotation, OCR, recording,
GIF export, pinning, and history are designed to work without cloud services.

## Reporting A Vulnerability

Please do not open a public issue for suspected security vulnerabilities.
Instead, use GitHub's private vulnerability reporting if it is enabled on the
repository, or contact the maintainer privately through GitHub.

Include:

- LocalShot version or commit SHA
- macOS version
- Steps to reproduce
- Expected and actual behavior
- Any relevant logs, screenshots, or crash reports

## Supported Versions

Only the current `main` branch and the latest GitHub release are expected to
receive fixes.

## Entitlements

The app keeps a small sandboxed entitlement set:

| Entitlement | Purpose |
| --- | --- |
| `com.apple.security.app-sandbox` | Run in the macOS App Sandbox |
| `com.apple.security.files.user-selected.read-write` | Save and open user-selected files |
| `com.apple.security.device.audio-input` | Record microphone audio when enabled by the user |
| `com.apple.security.temporary-exception.shared-preference.read-write` | Inspect and optionally disable overlapping macOS screenshot shortcuts when the user makes LocalShot the default |

Network client/server entitlements and public updater helper exceptions are
intentionally absent from the v1 LocalShot app.

## Local Data

- Exports: `~/Pictures/LocalShot`
- App support: `~/Library/Application Support/LocalShot`
- History database: `~/Library/Application Support/LocalShot/localshot.db`
- Local diagnostics: hidden and clamped off in v1

## Disabled In V1

- Cloud upload
- User accounts
- Telemetry and analytics
- Crash-report submission
- Public auto-update checks

## Permissions

macOS may request Screen Recording and Microphone permissions. Accessibility
should only be requested if a specific local feature requires it.
