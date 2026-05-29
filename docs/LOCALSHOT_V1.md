# LocalShot V1 Notes

## Scope

LocalShot v1 is a private local-first macOS screenshot and recording utility based on Snapzy. It keeps local capture, quick access, annotation, OCR, screen recording, GIF export, pinning, and history.

## Explicit Non-Goals

- Cloud upload
- User accounts
- Telemetry or analytics
- External crash-report submission
- Public auto-update checks
- Notarized public installer
- Complex video timeline editing

## Scrolling Capture Limitations

Scrolling capture uses the existing local stitcher and live preview. Unsupported or partial cases should be expected for custom canvas renderers, DRM/protected content, virtualized lists, apps that block scroll events, and documents where scrolling cannot be observed reliably.

Recommended manual coverage:

- Safari long webpage
- Chrome long webpage
- Finder list view
- VS Code source file
- Slack/Discord-like message view
- Long PDF or document viewer
- Failure state when scrolling cannot be detected

## Recording Limitations

MP4 is the default export. GIF export is kept as a secondary path. System audio availability depends on the macOS ScreenCaptureKit path and the user's permissions.

## Privacy Verification Targets

- The app should run with network disabled for local features.
- The packaged app should not have network client/server or Apple Events automation entitlements in v1.
- No upload, account, telemetry, crash-report submission, or auto-update controls should be visible in v1.
- Captures, recordings, GIFs, thumbnails, history metadata, and preferences should remain on this Mac.

Repeatable evidence:

- `scripts/localshot-verify.sh --with-launch-smoke`
- `build/evidence/localshot-verification-summary.txt`
- `build/evidence/tcc-status.txt`
- `build/evidence/localshot-launch-smoke.txt`

## Manual Runtime Verification Checklist

Use the installed app at `/Applications/LocalShot.app` for permission-sensitive checks. The packaged app remains available at `build/package/LocalShot.app`.

Before testing:

- Grant Screen Recording permission.
- Grant Microphone permission before microphone recording tests.
- Grant Accessibility only if a tested feature explicitly requests it.
- Disable network and confirm local capture, annotation, OCR, recording, GIF export, pinning, and history still work.

Capture:

- Area capture
- Window capture
- Full screen capture
- Previous area capture if available in the current build
- Multi-display placement if a second display is connected
- Retina scaling if a Retina display is available

Overlay and annotation:

- Quick Access copy, save, annotate, OCR, pin, delete, and drag-to-app
- Annotation arrow, text, rectangle, blur, pixelate, crop, numbered marker, undo, redo, copy, save, and done
- Pinned screenshots stay above normal windows and can be moved/closed

Recording:

- MP4 display-only recording
- MP4 microphone recording
- MP4 system audio plus microphone recording where ScreenCaptureKit supports it
- 30fps and 60fps options
- GIF export with small, balanced, and high-quality presets where available
- Stop, cancel, save, reveal in Finder, and delete result actions

History:

- Search, filter, open, copy, annotate, pin, reveal in Finder, delete
- Relaunch preserves local history
