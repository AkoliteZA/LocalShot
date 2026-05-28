#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${ROOT_DIR}/Snapzy.xcodeproj"
SCHEME="Snapzy"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="${ROOT_DIR}/build/DerivedData"
SOURCE_PACKAGES="${ROOT_DIR}/build/SourcePackages"
PRODUCT_APP="${DERIVED_DATA}/Build/Products/${CONFIGURATION}/LocalShot.app"
PACKAGE_DIR="${ROOT_DIR}/build/package"
PACKAGE_APP="${PACKAGE_DIR}/LocalShot.app"
BUNDLE_ID="com.personal.localshot"

build_app() {
  xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${DERIVED_DATA}" \
    -clonedSourcePackagesDirPath "${SOURCE_PACKAGES}" \
    -skipPackagePluginValidation \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_ALLOWED=YES \
    CODE_SIGNING_REQUIRED=NO \
    DEVELOPMENT_TEAM= \
    build
}

package_app() {
  build_app
  rm -rf "${PACKAGE_DIR}"
  mkdir -p "${PACKAGE_DIR}"
  ditto "${PRODUCT_APP}" "${PACKAGE_APP}"
  strip_v1_disabled_package_surfaces
  echo "Packaged ${PACKAGE_APP}"
}

strip_v1_disabled_package_surfaces() {
  local resources_dir="${PACKAGE_APP}/Contents/Resources"

  # V1 is a local-only app. Cloud entry points are gated in code, and the
  # packaged app also strips dormant cloud/update resource strings so they
  # cannot appear in UI recovery paths or bundle scans.
  if [[ -d "${resources_dir}" ]]; then
    find "${resources_dir}" -name "Cloud.strings" -type f -delete
    find "${resources_dir}" -name "manifest.json" -type f -delete

    local disabled_keys=(
      "action.cloud-uploads"
      "after-capture.cloud-alert-message"
      "after-capture.cloud-alert-title"
      "after-capture.upload-to-cloud-action"
      "after-capture.upload-to-cloud-description"
      "preferences-advanced.restore-defaults-confirmation-message"
      "preferences-history.upload-to-cloud"
      "preferences-history.uploaded-to-cloud"
      "preferences-history.uploaded-to-cloud-and-copied-link"
      "preferences-history.uploading-to-cloud"
      "preferences.tab.cloud"
      "annotate.cloud-not-configured-message"
      "annotate.cloud-not-configured-title"
      "annotate.inline-upload-failed-title"
      "annotate.overwrite-cloud-file-message"
      "annotate.overwrite-cloud-file-on-save-message"
      "annotate.overwrite-cloud-file-title"
      "annotate.reupload-to-cloud"
      "annotate.upload-to-cloud"
      "annotate.uploaded-to-cloud"
      "preferences-shortcuts.cloud-upload-description"
      "preferences-shortcuts.cloud-uploads-description"
      "shortcut-overlay.cloud-upload"
    )

    while IFS= read -r strings_file; do
      for key in "${disabled_keys[@]}"; do
        /usr/libexec/PlistBuddy -c "Delete :${key}" "${strings_file}" >/dev/null 2>&1 || true
      done
    done < <(find "${resources_dir}" -name "*.strings" -type f)
  fi

  /usr/bin/codesign \
    --force \
    --sign - \
    --entitlements "${ROOT_DIR}/Snapzy/Snapzy.entitlements" \
    --timestamp=none \
    "${PACKAGE_APP}" >/dev/null
}

install_app() {
  package_app
  rm -rf "/Applications/LocalShot.app"
  ditto "${PACKAGE_APP}" "/Applications/LocalShot.app"
  xattr -cr "/Applications/LocalShot.app" >/dev/null 2>&1 || true
  echo "Installed /Applications/LocalShot.app"
}

reset_permissions() {
  tccutil reset ScreenCapture "${BUNDLE_ID}" || true
  tccutil reset Microphone "${BUNDLE_ID}" || true
  tccutil reset Accessibility "${BUNDLE_ID}" || true
}

case "${1:-build}" in
  clean)
    rm -rf "${DERIVED_DATA}" "${SOURCE_PACKAGES}" "${PACKAGE_DIR}"
    ;;
  build)
    build_app
    ;;
  package)
    package_app
    ;;
  install)
    install_app
    ;;
  reset-permissions)
    reset_permissions
    ;;
  *)
    echo "Usage: $0 {clean|build|package|install|reset-permissions}" >&2
    exit 64
    ;;
esac
