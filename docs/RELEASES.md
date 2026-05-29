# Releases

LocalShot publishes downloadable builds through GitHub Releases.

## Current Release Shape

The included release workflow builds `LocalShot.app`, ad-hoc signs it with the
same local-first entitlements used by the build helper, zips the app, writes a
SHA-256 checksum, and attaches both files to a GitHub release.

Because the default workflow does not notarize the app with Apple, macOS may
warn that the downloaded app cannot be verified. Users who trust the release can
open it once with **Right-click > Open**.

## Publishing A Release

1. Update `CHANGELOG.md`.
2. Commit the release changes.
3. Push `main`.
4. Run the **Build Release** workflow from GitHub Actions.
5. Enter a tag such as `v1.20.1`.

The workflow creates or updates the tag and publishes:

- `LocalShot-vX.Y.Z.zip`
- `LocalShot-vX.Y.Z.zip.sha256`

## Notarized Releases

For the smoothest public install experience, add a future Developer ID release
workflow that:

- Imports a Developer ID Application certificate from GitHub Secrets.
- Builds and signs `LocalShot.app` with hardened runtime.
- Submits the archive to Apple notarization.
- Staples the notarization ticket.
- Publishes the notarized zip or DMG as the GitHub release asset.

Until then, releases are suitable for testers and users who are comfortable
with manually opening an ad-hoc signed macOS app.
