# Contributing To LocalShot

Thanks for helping improve LocalShot.

LocalShot is a native macOS screenshot and screen-recording app built with
SwiftUI, AppKit, CoreGraphics, and ScreenCaptureKit. Contributions should keep
the app local-first, privacy-conscious, and straightforward to build.

## Ways To Contribute

- Report bugs
- Propose features or UX improvements
- Improve documentation
- Submit focused fixes or new features
- Test changes on macOS 13 or newer

## Before You Start

- Search existing issues and pull requests before opening a new one.
- For larger changes, open an issue first so the approach can be discussed.
- Keep pull requests focused. Small, reviewable changes move fastest.
- Avoid unrelated renames, formatting sweeps, or broad refactors.

## Development Setup

Read [docs/BUILD.md](docs/BUILD.md) for build, package, install, and signing
notes.

Common commands:

```sh
./scripts/localshot-build.sh build
./scripts/localshot-build.sh install
./scripts/localshot-verify.sh --install-app --with-launch-smoke
```

The Xcode project and scheme are still named `Snapzy` internally. The product
name, bundle identifier, URL scheme, support paths, and user-facing app name are
LocalShot.

## Project Conventions

- Follow the existing Swift and SwiftUI style.
- Keep changes close to the feature they affect.
- Prefer feature folders with `Components`, `Models`, `Services`, or `Managers`
  only when they add clarity.
- Add comments only when intent is not obvious from the code.
- Update documentation when behavior, setup, privacy, permissions, or release
  workflow changes.
- Preserve local-first behavior unless the issue or pull request explicitly
  discusses a change.

## Validation

Before opening a pull request, include what you tested. Depending on the change,
that may include:

- Xcode build or `./scripts/localshot-build.sh build`
- Focused unit tests
- `./scripts/localshot-verify.sh --install-app --with-launch-smoke`
- Manual Screen Recording or Microphone permission checks
- Screenshots or short recordings for UI changes

Permission-sensitive flows should be tested with `/Applications/LocalShot.app`,
not a DerivedData app copy.

## Pull Request Checklist

- Describe what changed and why.
- Link related issues when available.
- Keep the change focused and reviewable.
- Include screenshots or recordings for visible UI changes.
- Note limitations or follow-up work.
- Explain how you tested it.

## Commit Messages

Use short, imperative messages. Conventional prefixes are welcome when useful:

- `feat: add capture option`
- `fix: speed up area capture startup`
- `docs: clarify install steps`
- `chore: update release workflow`

## Security Issues

Please do not report security vulnerabilities in public issues. See
[SECURITY.md](SECURITY.md).
