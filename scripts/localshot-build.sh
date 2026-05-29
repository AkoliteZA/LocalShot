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
INSTALLED_APP="/Applications/LocalShot.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
CODE_SIGN_IDENTITY_VALUE="${LOCALSHOT_CODE_SIGN_IDENTITY:--}"
CODE_SIGN_KEYCHAIN_VALUE="${LOCALSHOT_CODE_SIGN_KEYCHAIN:-}"
AD_HOC_DESIGNATED_REQUIREMENT="designated => identifier \"${BUNDLE_ID}\""

canonical_path() {
  local path="$1"
  local dir
  local base
  dir="$(dirname "${path}")"
  base="$(basename "${path}")"
  if [[ -d "${dir}" ]]; then
    printf '%s/%s\n' "$(cd "${dir}" && pwd -P)" "${base}"
  else
    printf '%s\n' "${path}"
  fi
}

unregister_launch_services_app() {
  local app="$1"
  if [[ -x "${LSREGISTER}" && -d "${app}" ]]; then
    "${LSREGISTER}" -u "${app}" >/dev/null 2>&1 || true
  fi
}

prune_launch_services_registrations() {
  if [[ ! -x "${LSREGISTER}" ]]; then
    return
  fi

  local installed_canonical
  installed_canonical="$(canonical_path "${INSTALLED_APP}")"

  # Xcode and test builds can register every DerivedData copy with Launch
  # Services, which makes Spotlight/App Search show many identical LocalShot
  # results. Keep only the installed app registered.
  if command -v mdfind >/dev/null 2>&1; then
    while IFS= read -r app; do
      [[ -z "${app}" ]] && continue
      if [[ "$(canonical_path "${app}")" != "${installed_canonical}" ]]; then
        unregister_launch_services_app "${app}"
      fi
    done < <(mdfind 'kMDItemFSName == "LocalShot.app"c' 2>/dev/null || true)
  fi

  for app in "${PRODUCT_APP}" "${PACKAGE_APP}"; do
    if [[ "$(canonical_path "${app}")" != "${installed_canonical}" ]]; then
      unregister_launch_services_app "${app}"
    fi
  done
}

remove_search_duplicate_apps() {
  if ! command -v mdfind >/dev/null 2>&1; then
    return
  fi

  local installed_canonical
  installed_canonical="$(canonical_path "${INSTALLED_APP}")"

  while IFS= read -r app; do
    [[ -z "${app}" ]] && continue
    if [[ "$(canonical_path "${app}")" != "${installed_canonical}" && -d "${app}" ]]; then
      unregister_launch_services_app "${app}"
      rm -rf "${app}"
    fi
  done < <(mdfind 'kMDItemFSName == "LocalShot.app"c' 2>/dev/null || true)
}

codesign_args() {
  local args=(
    --force \
    --sign "${CODE_SIGN_IDENTITY_VALUE}" \
    --entitlements "${ROOT_DIR}/Snapzy/Snapzy.entitlements" \
    --timestamp=none
  )

  if [[ "${CODE_SIGN_IDENTITY_VALUE}" == "-" ]]; then
    args+=("-r=${AD_HOC_DESIGNATED_REQUIREMENT}")
  fi

  if [[ -n "${CODE_SIGN_KEYCHAIN_VALUE}" ]]; then
    args+=(--keychain "${CODE_SIGN_KEYCHAIN_VALUE}")
  fi

  printf '%s\0' "${args[@]}"
}

xcodebuild_signing_args=(
  CODE_SIGN_STYLE=Manual
  "CODE_SIGN_IDENTITY=${CODE_SIGN_IDENTITY_VALUE}"
  CODE_SIGNING_ALLOWED=YES
  CODE_SIGNING_REQUIRED=NO
  DEVELOPMENT_TEAM=
)

if [[ -n "${CODE_SIGN_KEYCHAIN_VALUE}" ]]; then
  xcodebuild_signing_args+=("OTHER_CODE_SIGN_FLAGS=--keychain ${CODE_SIGN_KEYCHAIN_VALUE}")
fi

build_app() {
  xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${DERIVED_DATA}" \
    -clonedSourcePackagesDirPath "${SOURCE_PACKAGES}" \
    -skipPackagePluginValidation \
    "${xcodebuild_signing_args[@]}" \
    build
  prune_launch_services_registrations
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
      "onboarding.sponsor.title"
      "onboarding.sponsor.description"
      "onboarding.sponsor.optional-note"
      "sponsor.recurring-support"
      "sponsor.one-time-tip"
      "sponsor.direct-support"
      "preferences-about.support-title"
      "preferences-about.support-description"
      "crash-report.accessory-hint"
      "crash-report.alert-message"
      "crash-report.alert-message-no-log-bundle"
      "crash-report.alert-title"
      "crash-report.dismiss"
      "crash-report.submit"
      "preferences-about.report-bug"
      "preferences-about.report-problem"
      "preferences-general.open-report-page-button"
      "preferences-general.report-issue-description"
      "preferences-general.report-issue-title"
    )

    while IFS= read -r strings_file; do
      for key in "${disabled_keys[@]}"; do
        /usr/libexec/PlistBuddy -c "Delete :${key}" "${strings_file}" >/dev/null 2>&1 || true
      done
    done < <(find "${resources_dir}" -name "*.strings" -type f)
  fi

  local args=()
  while IFS= read -r -d '' arg; do
    args+=("${arg}")
  done < <(codesign_args)

  /usr/bin/codesign "${args[@]}" "${PACKAGE_APP}" >/dev/null
}

install_app() {
  package_app
  rm -rf "${INSTALLED_APP}"
  ditto "${PACKAGE_APP}" "${INSTALLED_APP}"
  xattr -cr "${INSTALLED_APP}" >/dev/null 2>&1 || true
  refresh_launch_services_registration
  echo "Installed ${INSTALLED_APP}"
}

refresh_launch_services_registration() {
  if [[ ! -x "${LSREGISTER}" ]]; then
    return
  fi

  prune_launch_services_registrations
  "${LSREGISTER}" -f -R -trusted "${INSTALLED_APP}" >/dev/null 2>&1 || true
}

reset_permissions() {
  if ! tccutil reset All "${BUNDLE_ID}"; then
    tccutil reset ScreenCapture "${BUNDLE_ID}" || true
    tccutil reset Microphone "${BUNDLE_ID}" || true
    tccutil reset Accessibility "${BUNDLE_ID}" || true
  fi

  # Security-scoped bookmarks are app state, not TCC rows. Clear the export
  # bookmark as part of the dev reset so the next launch asks for the folder
  # with the currently installed app identity.
  defaults delete "${BUNDLE_ID}" "exportLocation.bookmark" >/dev/null 2>&1 || true
}

signing_info() {
  echo "Configured signing identity: ${CODE_SIGN_IDENTITY_VALUE}"
  if [[ -n "${CODE_SIGN_KEYCHAIN_VALUE}" ]]; then
    echo "Configured signing keychain: ${CODE_SIGN_KEYCHAIN_VALUE}"
  fi
  echo
  echo "Available code-signing identities:"
  security find-identity -v -p codesigning
  echo
  if [[ "${CODE_SIGN_IDENTITY_VALUE}" == "-" ]]; then
    cat <<'INFO'
Using ad-hoc signing. This is valid for local builds, but macOS privacy
permissions are sensitive to the code identity macOS records in TCC.
The packaged app is signed with a stable LocalShot designated requirement so
grants survive ordinary local rebuilds after you reset and grant once.

For stronger identity binding, create or install a trusted code-signing
certificate and run:

  LOCALSHOT_CODE_SIGN_IDENTITY="Certificate Common Name" scripts/localshot-build.sh install

Optionally set LOCALSHOT_CODE_SIGN_KEYCHAIN to the keychain containing it.
INFO
  fi

  echo
  for app in "${PACKAGE_APP}" "${INSTALLED_APP}"; do
    if [[ -d "${app}" ]]; then
      echo "Designated requirement for ${app}:"
      codesign -d -r- "${app}" 2>&1 | sed 's/^/  /'
      echo
    fi
  done

  echo
  echo "Registered LocalShot app copies:"
  if [[ -x "${LSREGISTER}" ]]; then
    "${LSREGISTER}" -dump 2>/dev/null \
      | awk '/path:[[:space:]].*LocalShot\.app/{path=$0} /identifier:[[:space:]]+com\.personal\.localshot/{print path}' \
      | sed 's/^[[:space:]]*path:[[:space:]]*/  /' \
      | sort -u
  else
    echo "  LaunchServices registrar not found"
  fi
}

case "${1:-build}" in
  clean)
    prune_launch_services_registrations
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
  clean-launch-services)
    refresh_launch_services_registration
    ;;
  clean-search-duplicates)
    prune_launch_services_registrations
    remove_search_duplicate_apps
    refresh_launch_services_registration
    ;;
  signing-info)
    signing_info
    ;;
  *)
    echo "Usage: $0 {clean|build|package|install|reset-permissions|clean-launch-services|clean-search-duplicates|signing-info}" >&2
    exit 64
    ;;
esac
