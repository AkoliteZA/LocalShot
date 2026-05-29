# LocalShot

LocalShot is a private, local-first macOS screenshot and screen-recording utility forked from Snapzy.

This v1 fork is for personal local use on macOS 13+. It keeps the Snapzy BSD-3-Clause attribution and focuses on capture, quick access, annotation, OCR, pinning, local history, MP4 recording, and GIF export without cloud upload, accounts, telemetry, crash reporting, or public auto-update infrastructure.

## Privacy Defaults

- Saves exports to `~/Pictures/LocalShot` by default.
- Stores app data under `~/Library/Application Support/LocalShot`.
- Uses `localshot://` for local automation links.
- Does not configure cloud storage, login, account tokens, telemetry IDs, crash-report submission, public update feeds, or update checks in v1.
- Keeps diagnostic logging controls hidden and clamps imported/local settings off for v1.

## Build

Use the local helper:

```sh
./scripts/localshot-build.sh build
./scripts/localshot-build.sh package
./scripts/localshot-build.sh install
```

The helper builds the existing Xcode scheme with local DerivedData and source package folders. It signs ad-hoc for local use when possible and does not notarize.

## Verify

Run the repeatable v1 verifier:

```sh
./scripts/localshot-verify.sh --install-app --with-launch-smoke
```

The verifier builds/tests/packages the app, checks bundle metadata and guardrails, records current TCC permission rows for `com.personal.localshot`, verifies the package has no network or Apple Events automation entitlement, installs to `/Applications/LocalShot.app` when requested, and can launch-smoke either the package or installed app. Live capture and recording checks still require macOS Screen Recording and Microphone permission grants.

## Local URLs

LocalShot registers a private URL scheme for local automation:

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

Cloud upload and complex video-editor deep links are intentionally disabled in v1.

## Attribution

LocalShot is based on Snapzy by Trong Duong Duc, used under the BSD 3-Clause License. See `LICENSE` for the original license notice.
