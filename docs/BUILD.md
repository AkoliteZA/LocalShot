# Build LocalShot

LocalShot keeps the upstream Xcode project and scheme names internally, but the built app product is `LocalShot.app`.

## Commands

```sh
./scripts/localshot-build.sh clean
./scripts/localshot-build.sh build
./scripts/localshot-build.sh package
./scripts/localshot-build.sh install
```

The helper uses:

- Project: `Snapzy.xcodeproj`
- Scheme: `Snapzy`
- DerivedData: `build/DerivedData`
- Source packages: `build/SourcePackages`
- Product: `build/DerivedData/Build/Products/Debug/LocalShot.app`
- Package copy: `build/package/LocalShot.app`

## Notes

- v1 is for local personal use.
- The helper signs ad-hoc when possible.
- Notarization, public release feeds, and update checks are not part of v1.
