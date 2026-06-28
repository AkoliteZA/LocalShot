# Homebrew

LocalShot ships a Homebrew cask in `Casks/localshot.rb`.

## Install

This repository can be used as a Homebrew tap with an explicit remote:

```sh
brew tap AkoliteZA/localshot https://github.com/AkoliteZA/LocalShot
brew trust AkoliteZA/localshot
brew install localshot
```

After the tap is added, future upgrades use the normal Homebrew commands:

```sh
brew update
brew upgrade localshot
```

The `brew trust` step allows Homebrew to resolve the short cask name from this
non-official tap. Without it, Homebrew may ask you to install with the fully
qualified tap name instead of `brew install localshot`.

You can uninstall the app with:

```sh
brew uninstall localshot
```

To remove LocalShot's local app data as well:

```sh
brew uninstall --zap localshot
```

## Why The Tap Uses An Explicit URL

Homebrew's short tap syntax, such as `brew tap AkoliteZA/localshot`, looks for a
GitHub repository named `AkoliteZA/homebrew-localshot`. This repository is named
`AkoliteZA/LocalShot`, so the tap command includes the repository URL.

If LocalShot later gets a dedicated `AkoliteZA/homebrew-localshot` tap, the same
cask file can be copied there and users can install with:

```sh
brew install AkoliteZA/localshot/localshot
```

If LocalShot is accepted into the official Homebrew cask repository, a fresh Mac
will be able to run `brew install localshot` without adding a tap first.

## Maintainer Workflow

The release workflow updates `Casks/localshot.rb` from the generated release
checksum before it tags the release commit.

To update the cask manually after publishing a release:

```sh
./scripts/update-homebrew-cask.sh v1.20.1 build/LocalShot-v1.20.1.zip.sha256
```

To check the cask:

```sh
./scripts/check-homebrew-cask.sh
./scripts/check-homebrew-cask.sh --verify-release
./scripts/check-homebrew-cask.sh --brew-audit
./scripts/check-homebrew-cask.sh --install-dry-run
```
