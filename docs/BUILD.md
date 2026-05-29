# Build LocalShot

LocalShot keeps the upstream Xcode project and scheme names internally, but the built app product is `LocalShot.app`.

## Commands

```sh
./scripts/localshot-build.sh clean
./scripts/localshot-build.sh build
./scripts/localshot-build.sh package
./scripts/localshot-build.sh install
./scripts/localshot-build.sh signing-info
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
- By default the helper signs ad-hoc. That is enough to launch locally, but
  macOS privacy permissions such as Screen Recording can be invalidated after
  reinstalling a rebuilt app because the ad-hoc code identity changes.
- To avoid repeated Screen Recording grants during development, install a
  trusted local code-signing certificate and run builds with
  `LOCALSHOT_CODE_SIGN_IDENTITY="Certificate Common Name"`. If the certificate
  is in a non-default keychain, also set `LOCALSHOT_CODE_SIGN_KEYCHAIN`.
- You can create a stable local identity in Keychain Access with
  **Certificate Assistant > Create a Certificate...**, using an Identity Type
  of **Self Signed Root** and Certificate Type **Code Signing**. After it
  appears in `./scripts/localshot-build.sh signing-info`, rebuild/install with
  `LOCALSHOT_CODE_SIGN_IDENTITY` set to the certificate name, then reset and
  re-grant macOS permissions once for that signed app.
- For permission-sensitive testing, quit DerivedData test copies and run the
  installed `/Applications/LocalShot.app`. Save Folder access is granted from
  LocalShot's folder picker, not System Settings. Microphone appears in
  System Settings only after LocalShot requests microphone access once.
- Notarization, public release feeds, and update checks are not part of v1.
