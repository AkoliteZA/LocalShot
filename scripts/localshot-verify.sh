#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${ROOT_DIR}/Snapzy.xcodeproj"
SCHEME="Snapzy"
CONFIGURATION="${CONFIGURATION:-Debug}"
BUNDLE_ID="com.personal.localshot"
DERIVED_DATA="${ROOT_DIR}/build/DerivedData"
SOURCE_PACKAGES="${ROOT_DIR}/build/SourcePackages"
PACKAGE_APP="${ROOT_DIR}/build/package/LocalShot.app"
EVIDENCE_DIR="${ROOT_DIR}/build/evidence"
MOCKUPS_DIR="$(cd "${ROOT_DIR}/.." && pwd)/mockups"

SKIP_TESTS=0
SKIP_PACKAGE=0
RUN_LAUNCH_SMOKE=0

usage() {
  cat <<'USAGE'
Usage: scripts/localshot-verify.sh [--skip-tests] [--skip-package] [--with-launch-smoke]

Runs repeatable LocalShot v1 verification and writes evidence under build/evidence.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-tests)
      SKIP_TESTS=1
      ;;
    --skip-package)
      SKIP_PACKAGE=1
      ;;
    --with-launch-smoke)
      RUN_LAUNCH_SMOKE=1
      ;;
    -h|--help)
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

mkdir -p "${EVIDENCE_DIR}"
SUMMARY="${EVIDENCE_DIR}/localshot-verification-summary.txt"
: > "${SUMMARY}"

record() {
  printf '%s\n' "$*" | tee -a "${SUMMARY}"
}

run_capture() {
  local label="$1"
  local output="$2"
  shift 2
  record "RUN ${label}"
  if "$@" > "${output}" 2>&1; then
    record "PASS ${label}: ${output}"
  else
    local status=$?
    record "FAIL ${label}: ${output} (exit ${status})"
    tail -80 "${output}" >&2 || true
    exit "${status}"
  fi
}

fail_if_hits() {
  local label="$1"
  local output="$2"
  shift 2
  record "SCAN ${label}"
  if "$@" > "${output}" 2>&1; then
    record "FAIL ${label}: hits written to ${output}"
    sed -n '1,120p' "${output}" >&2
    exit 1
  else
    local status=$?
    if [[ "${status}" -eq 1 ]]; then
      : > "${output}"
      record "PASS ${label}: no hits"
    else
      record "FAIL ${label}: scanner exited ${status}"
      sed -n '1,120p' "${output}" >&2 || true
      exit "${status}"
    fi
  fi
}

fail_if_output() {
  local label="$1"
  local output="$2"
  shift 2
  record "SCAN ${label}"
  if "$@" > "${output}" 2>&1; then
    if [[ -s "${output}" ]]; then
      record "FAIL ${label}: hits written to ${output}"
      sed -n '1,120p' "${output}" >&2
      exit 1
    fi
    record "PASS ${label}: no hits"
  else
    local status=$?
    record "FAIL ${label}: scanner exited ${status}"
    sed -n '1,120p' "${output}" >&2 || true
    exit "${status}"
  fi
}

run_launch_smoke() {
  local output="${EVIDENCE_DIR}/localshot-launch-smoke.txt"
  record "RUN launch smoke"
  : > "${output}"

  if pgrep -x LocalShot > "${EVIDENCE_DIR}/localshot-launch-preexisting-pids.txt" 2>/dev/null; then
    record "FAIL launch smoke: LocalShot is already running; stop it before isolated launch verification"
    cat "${EVIDENCE_DIR}/localshot-launch-preexisting-pids.txt" >> "${output}"
    exit 1
  fi

  {
    echo "Launch smoke started: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "App: ${PACKAGE_APP}"
    open -n "${PACKAGE_APP}"
    sleep 3
    echo "Process IDs:"
    pgrep -x LocalShot
    echo "TCC rows:"
    sqlite3 "${HOME}/Library/Application Support/com.apple.TCC/TCC.db" \
      "select service, client, auth_value, auth_reason, auth_version, datetime(last_modified,'unixepoch') from access where client = '${BUNDLE_ID}' order by service;" \
      2>/dev/null || echo "TCC database unavailable to verifier"
  } > "${output}" 2>&1 || {
    local status=$?
    pkill -x LocalShot 2>/dev/null || true
    record "FAIL launch smoke: ${output} (exit ${status})"
    tail -80 "${output}" >&2 || true
    exit "${status}"
  }

  pkill -x LocalShot 2>/dev/null || true
  record "PASS launch smoke: ${output}"
}

record "LocalShot verification started: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
record "Repo: ${ROOT_DIR}"
record "Commit: $(git -C "${ROOT_DIR}" rev-parse HEAD)"
record "Branch: $(git -C "${ROOT_DIR}" branch --show-current)"

run_capture \
  "xcodebuild -list" \
  "${EVIDENCE_DIR}/xcodebuild-list.txt" \
  xcodebuild -list -project "${PROJECT}"

if [[ "${SKIP_TESTS}" -eq 0 ]]; then
  run_capture \
    "full serial tests" \
    "${EVIDENCE_DIR}/xcodebuild-test.txt" \
    xcodebuild test \
      -project "${PROJECT}" \
      -scheme "${SCHEME}" \
      -configuration "${CONFIGURATION}" \
      -derivedDataPath "${DERIVED_DATA}" \
      -clonedSourcePackagesDirPath "${SOURCE_PACKAGES}" \
      -skipPackagePluginValidation \
      -parallel-testing-enabled NO \
      CODE_SIGN_STYLE=Manual \
      CODE_SIGN_IDENTITY=- \
      CODE_SIGNING_ALLOWED=YES \
      CODE_SIGNING_REQUIRED=NO \
      DEVELOPMENT_TEAM=
else
  record "SKIP full serial tests"
fi

if [[ "${SKIP_PACKAGE}" -eq 0 ]]; then
  run_capture \
    "package app" \
    "${EVIDENCE_DIR}/localshot-package.txt" \
    "${ROOT_DIR}/scripts/localshot-build.sh" package
else
  record "SKIP package app"
fi

if [[ ! -d "${PACKAGE_APP}" ]]; then
  record "FAIL package exists: ${PACKAGE_APP} missing"
  exit 1
fi

run_capture \
  "codesign verify" \
  "${EVIDENCE_DIR}/codesign-verify.txt" \
  codesign --verify --deep --strict --verbose=2 "${PACKAGE_APP}"

{
  /usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "${PACKAGE_APP}/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleName' "${PACKAGE_APP}/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${PACKAGE_APP}/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes:0:CFBundleURLSchemes:0' "${PACKAGE_APP}/Contents/Info.plist"
  codesign -d --entitlements :- "${PACKAGE_APP}" 2>/dev/null
} > "${EVIDENCE_DIR}/package-metadata.txt"
record "PASS package metadata: ${EVIDENCE_DIR}/package-metadata.txt"

fail_if_hits \
  "package network entitlement guardrails" \
  "${EVIDENCE_DIR}/package-network-entitlement-hits.txt" \
  bash -c 'codesign -d --entitlements :- "$1" 2>/dev/null | rg -n "com\\.apple\\.security\\.network\\.(client|server)|com\\.apple\\.security\\.automation\\.apple-events"' \
    _ "${PACKAGE_APP}"

{
  echo "Bundle ID: ${BUNDLE_ID}"
  echo "Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "TCC rows:"
  sqlite3 "${HOME}/Library/Application Support/com.apple.TCC/TCC.db" \
    "select service, client, auth_value, auth_reason, auth_version, datetime(last_modified,'unixepoch') from access where client = '${BUNDLE_ID}' order by service;" \
    2>/dev/null || echo "TCC database unavailable to verifier"
} > "${EVIDENCE_DIR}/tcc-status.txt"
record "PASS TCC status snapshot: ${EVIDENCE_DIR}/tcc-status.txt"

if [[ "${RUN_LAUNCH_SMOKE}" -eq 1 ]]; then
  run_launch_smoke
else
  record "SKIP launch smoke"
fi

fail_if_hits \
  "source CleanShot/update/rebrand guardrails" \
  "${EVIDENCE_DIR}/source-guardrail-hits.txt" \
  rg -n "CleanShot|CleanShot X|Sparkle|SUUpdater|SPUUpdater|SUFeed|SUPublic|appcast|com\\.trongduong\\.snapzy|snapzy://|SnapzyIcon|Snapzy\\.app" \
    "${ROOT_DIR}" \
    --glob '!/.git/**' \
    --glob '!build/**' \
    --glob '!scripts/localshot-verify.sh'

fail_if_hits \
  "package CleanShot/update/rebrand guardrails" \
  "${EVIDENCE_DIR}/package-guardrail-hits.txt" \
  rg -n "CleanShot|CleanShot X|Sparkle|SUUpdater|SPUUpdater|SUFeed|SUPublic|appcast|com\\.trongduong\\.snapzy|snapzy://|SnapzyIcon|Snapzy\\.app|Snapzy" \
    "${PACKAGE_APP}"

fail_if_hits \
  "package local-first resource guardrails" \
  "${EVIDENCE_DIR}/package-resource-guardrail-hits.txt" \
  rg -n "upload|cloud|account|telemetry|analytics|Sparkle|SUUpdater|S3|R2" \
    "${PACKAGE_APP}/Contents/Resources" \
    --glob '*.strings' \
    --glob '*.plist' \
    --glob '*.json'

fail_if_output \
  "package local-first filename guardrails" \
  "${EVIDENCE_DIR}/package-filename-guardrail-hits.txt" \
  find "${PACKAGE_APP}" \( \
    -iname '*CleanShot*' \
    -o -iname '*Snapzy*' \
    -o -iname '*Sparkle*' \
    -o -iname '*cloud*' \
    -o -iname '*upload*' \
    -o -iname '*account*' \
    -o -iname '*telemetry*' \
    -o -iname '*analytics*' \
  \) -print

find "${MOCKUPS_DIR}" -maxdepth 1 -type f -name 'localshot-*.png' | sort > "${EVIDENCE_DIR}/mockups.txt"
mockup_count="$(wc -l < "${EVIDENCE_DIR}/mockups.txt" | tr -d ' ')"
if [[ "${mockup_count}" -lt 5 ]]; then
  record "FAIL mockup inventory: expected at least 5, got ${mockup_count}"
  exit 1
fi
record "PASS mockup inventory: ${mockup_count} files"

git -C "${ROOT_DIR}" status --short > "${EVIDENCE_DIR}/git-status.txt"
git -C "${ROOT_DIR}" diff --stat > "${EVIDENCE_DIR}/git-diff-stat.txt"
record "PASS git evidence: ${EVIDENCE_DIR}/git-status.txt"

record "LocalShot verification finished: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
