# LocalShot

LocalShot is a local-first macOS screenshot and screen-recording app.

This repository is explicitly a fork of Snapzy by Trong Duong Duc, not an
original project written from scratch. LocalShot keeps the Snapzy BSD 3-Clause
license and attribution while adding LocalShot-specific branding, privacy
defaults, shortcut controls, settings updates, Quick Access behavior, and local
release tooling.

The app is built with Swift, SwiftUI, AppKit, CoreGraphics, and
ScreenCaptureKit. It targets macOS 13 or newer.

![LocalShot banner](banner.png)

## Why Choose LocalShot?

LocalShot is for people who like Snapzy's native macOS capture foundation but
want a tighter local-first tool with fewer online/service surfaces and more
control over the everyday screenshot workflow.

Compared with upstream Snapzy, LocalShot adds:

- **Local-only defaults**: screenshots, recordings, OCR, pins, and history are
  designed to work without cloud upload, telemetry, public crash-report
  submission, sponsor prompts, or public update checks.
- **Default macOS screenshot shortcuts**: LocalShot can take over `⌘⇧3`,
  `⌘⇧4`, and `⌘⇧5` from Settings and turn off the overlapping built-in macOS
  screenshot shortcuts.
- **Previous-area capture**: quickly recapture the last selected screenshot
  region.
- **Richer Quick Access cards**: copy, annotate, OCR, pin, delete, drag, and
  close/dismiss actions can be arranged into configurable button slots.
- **Quick Access OCR**: copy recognized text and QR content directly from the
  floating screenshot card.
- **Pinned screenshot controls**: keep screenshots above other windows and use
  short hover tooltips for the pinned-window controls.
- **LocalShot-specific packaging and verification**: scripts build, install,
  verify, and reset permissions for `/Applications/LocalShot.app`, which helps
  avoid macOS privacy-permission churn during local builds.
- **Clear fork attribution**: LocalShot keeps Snapzy's BSD 3-Clause license and
  credits while documenting the LocalShot-specific changes.

Snapzy remains the broader upstream app, especially if you want built-in cloud
upload, Sparkle updates, public support/sponsor surfaces, or the full video
editor workflow. Choose LocalShot when you want the local, privacy-focused path.

## Features

- Area, window, full-screen, previous-area, and scrolling screenshots
- Quick Access card with copy, annotate, OCR, pin, delete, and drag actions
- Pinned screenshots that stay above normal windows
- Local annotation tools for shapes, arrows, text, crop, blur, pixelate, and markers
- OCR text capture
- Local history with search, copy, reveal, annotate, pin, and delete
- MP4 screen recording with optional microphone and system audio where supported
- GIF export presets
- Configurable shortcuts, including an option to make LocalShot the default screenshot app
- No cloud account, telemetry, analytics, crash-report submission, or public update feed

## Download

Download the latest build from the
[GitHub Releases](https://github.com/AkoliteZA/LocalShot/releases) page once
releases are published.

Current public builds are ad-hoc signed unless a maintainer publishes a
Developer ID-notarized release. macOS may warn that the app cannot be verified.
If you trust the downloaded release, open it from Finder with
**Right-click > Open** the first time.

## Install From Source

Requirements:

- macOS 13+
- Xcode with macOS SDK support
- Git

Build and install locally:

```sh
git clone https://github.com/AkoliteZA/LocalShot.git
cd LocalShot
./scripts/localshot-build.sh install
open /Applications/LocalShot.app
```

The helper keeps Xcode's internal project and scheme names as `Snapzy`, but the
built product is `LocalShot.app`.

## Permissions

LocalShot uses macOS privacy permissions for capture and recording:

- Screen Recording: required for screenshots and screen recording
- Microphone: required only for microphone recording
- Save Folder access: granted from LocalShot's folder picker
- Accessibility: requested only by features that need it

For permission-sensitive testing, use the installed app at
`/Applications/LocalShot.app`, not a DerivedData build copy.

## Privacy

By default LocalShot stores data locally:

- Exports: `~/Pictures/LocalShot`
- App data: `~/Library/Application Support/LocalShot`
- History database: `~/Library/Application Support/LocalShot/localshot.db`

The v1 LocalShot build intentionally removes public cloud upload, accounts,
telemetry, analytics, crash-report submission, and update-check surfaces.

## Development

Useful commands:

```sh
./scripts/localshot-build.sh build
./scripts/localshot-build.sh package
./scripts/localshot-build.sh install
./scripts/localshot-verify.sh --install-app --with-launch-smoke
```

More detail is in [docs/BUILD.md](docs/BUILD.md) and
[docs/LOCALSHOT_V1.md](docs/LOCALSHOT_V1.md).

## Local URLs

LocalShot registers a local URL scheme:

| Action | URL |
| --- | --- |
| Fullscreen screenshot | `localshot://capture/fullscreen` |
| Area screenshot | `localshot://capture/area` |
| Area annotate | `localshot://capture/area-annotate` |
| Scrolling screenshot | `localshot://capture/scrolling` |
| OCR text capture | `localshot://capture/ocr` |
| Screen recording | `localshot://record/screen` |
| Open Annotate | `localshot://open/annotate` |
| Open History | `localshot://open/history` |
| Show shortcuts list | `localshot://show/shortcuts` |
| Open Settings | `localshot://settings` |

## Contributing

Bug reports, feature ideas, documentation improvements, and focused pull
requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License And Attribution

LocalShot is a fork of Snapzy by Trong Duong Duc and is distributed under the
BSD 3-Clause License. The original author and license notice are preserved in
[LICENSE](LICENSE), with additional attribution in [NOTICE.md](NOTICE.md).
