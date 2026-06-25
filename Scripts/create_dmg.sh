#!/usr/bin/env bash
# Pack Muzeebra.app into a drag-and-drop installer DMG.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Muzeebra"
APP_BUNDLE="${ROOT_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
DMG_PATH="${ROOT_DIR}/${DMG_NAME}"
TEMP_DIR="${ROOT_DIR}/tmp_dmg"

log() { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Build app bundle if it doesn't exist yet
if [[ ! -d "${APP_BUNDLE}" ]]; then
  log "==> App bundle not found at ${APP_BUNDLE}. Building and packaging app first..."
  "${ROOT_DIR}/Scripts/package_app.sh" release
fi

log "==> Preparing temporary directory for DMG packaging..."
rm -rf "${TEMP_DIR}"
mkdir -p "${TEMP_DIR}"

log "==> Copying app to temporary folder..."
cp -R "${APP_BUNDLE}" "${TEMP_DIR}/"

log "==> Creating /Applications symlink..."
ln -s /Applications "${TEMP_DIR}/Applications"

log "==> Creating DMG file..."
rm -f "${DMG_PATH}"
hdiutil create -volname "${APP_NAME}" -srcfolder "${TEMP_DIR}" -ov -format UDZO "${DMG_PATH}"

log "==> Cleaning up temporary files..."
rm -rf "${TEMP_DIR}"

log "==> Success! DMG created at: ${DMG_PATH}"
