#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASK_PATH="${ROOT_DIR}/Casks/localshot.rb"
VERIFY_RELEASE=0
RUN_BREW_AUDIT=0
RUN_INSTALL_DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage: scripts/check-homebrew-cask.sh [--verify-release] [--brew-audit] [--install-dry-run]

Checks that Casks/localshot.rb is a usable Homebrew cask for the current
GitHub release asset. --verify-release compares the cask checksum against the
published .sha256 file. --brew-audit runs Homebrew's cask audit when brew is
available. --install-dry-run verifies that `brew install localshot` resolves
from a trusted temporary tap.
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]
do
  case "$1" in
    --verify-release)
      VERIFY_RELEASE=1
      ;;
    --brew-audit)
      RUN_BREW_AUDIT=1
      ;;
    --install-dry-run)
      RUN_INSTALL_DRY_RUN=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 64
      ;;
  esac
  shift
done

[[ -f "${CASK_PATH}" ]] || die "missing ${CASK_PATH}"

ruby -c "${CASK_PATH}" >/dev/null

grep -Fq 'cask "localshot" do' "${CASK_PATH}" ||
  die "cask token must be localshot"
grep -Fq 'url "https://github.com/AkoliteZA/LocalShot/releases/download/v#{version}/LocalShot-v#{version}.zip"' "${CASK_PATH}" ||
  die "cask url must point at the LocalShot GitHub release zip"
grep -Fq 'homepage "https://github.com/AkoliteZA/LocalShot"' "${CASK_PATH}" ||
  die "cask homepage must point at the LocalShot repository"
grep -Fq 'app "LocalShot.app"' "${CASK_PATH}" ||
  die "cask must install LocalShot.app"
grep -Fq 'depends_on macos: :ventura' "${CASK_PATH}" ||
  die "cask must declare the macOS 13 minimum"

# shellcheck disable=SC2016 # Ruby uses $1 for the first regex capture.
version="$(ruby -ne 'puts $1 and exit if /^\s*version "([^"]+)"/' "${CASK_PATH}")"
# shellcheck disable=SC2016 # Ruby uses $1 for the first regex capture.
sha256="$(ruby -ne 'puts $1 and exit if /^\s*sha256 "([0-9a-f]{64})"/' "${CASK_PATH}")"

[[ -n "${version}" ]] || die "missing version stanza"
[[ -n "${sha256}" ]] || die "missing fixed sha256 stanza"

if [[ "${VERIFY_RELEASE}" -eq 1 ]]
then
  tag="v${version}"
  checksum_url="https://github.com/AkoliteZA/LocalShot/releases/download/${tag}/LocalShot-${tag}.zip.sha256"
  published_sha="$(curl -fsSL "${checksum_url}" | awk '{print $1}')"
  [[ "${published_sha}" == "${sha256}" ]] ||
    die "sha256 mismatch: cask has ${sha256}, release has ${published_sha}"
fi

if [[ "${RUN_BREW_AUDIT}" -eq 1 || "${RUN_INSTALL_DRY_RUN}" -eq 1 ]]
then
  if ! command -v brew >/dev/null 2>&1
  then
    die "brew not found"
  fi
  tmp_tap_dir="$(mktemp -d)"
  tap_name="localshot/cask-check-$$"
  cleanup_tap() {
    brew untap "${tap_name}" >/dev/null 2>&1 || true
    rm -rf "${tmp_tap_dir}"
  }
  trap cleanup_tap EXIT

  mkdir -p "${tmp_tap_dir}/Casks"
  cp "${CASK_PATH}" "${tmp_tap_dir}/Casks/localshot.rb"
  git -C "${tmp_tap_dir}" init -q
  git -C "${tmp_tap_dir}" config user.name "LocalShot Cask Check"
  git -C "${tmp_tap_dir}" config user.email "localshot@example.invalid"
  git -C "${tmp_tap_dir}" add Casks/localshot.rb
  git -C "${tmp_tap_dir}" commit -q -m "Add localshot cask"

  brew tap "${tap_name}" "${tmp_tap_dir}" >/dev/null
fi

if [[ "${RUN_BREW_AUDIT}" -eq 1 ]]
then
  brew audit --cask --tap="${tap_name}" localshot
fi

if [[ "${RUN_INSTALL_DRY_RUN}" -eq 1 ]]
then
  brew trust "${tap_name}" >/dev/null
  brew install --dry-run localshot
fi

printf 'Homebrew cask check passed: localshot %s\n' "${version}"
