# LocalShot Security and Privacy

LocalShot v1 is a local-only personal fork. The app is expected to work without network access for capture, annotation, OCR, recording, GIF export, pinning, and local history.

## Entitlements

The v1 app keeps only the entitlements needed for a sandboxed local macOS utility:

| Entitlement | Purpose |
| --- | --- |
| `com.apple.security.app-sandbox` | Run in the macOS App Sandbox |
| `com.apple.security.files.user-selected.read-write` | Save and open user-selected files |
| `com.apple.security.device.audio-input` | Record microphone audio when enabled by the user |
| `com.apple.security.temporary-exception.shared-preference.read-only` | Inspect system hotkey preferences for conflict warnings |

Network client entitlement and public updater helper exceptions are intentionally absent.

## Local Data

- Exports: `~/Pictures/LocalShot`
- App support: `~/Library/Application Support/LocalShot`
- History database: `~/Library/Application Support/LocalShot/localshot.db`
- Local diagnostics: disabled by default and stored locally only if enabled

## Disabled In V1

- Cloud upload
- User accounts
- Telemetry and analytics
- Crash-report submission
- Public auto-update checks
- Notarized public release workflow

## Permissions

macOS may request Screen Recording and Microphone permissions. Accessibility should only be requested if a specific local feature requires it.
