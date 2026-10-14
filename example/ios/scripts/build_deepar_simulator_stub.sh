#!/bin/bash
# Builds a simulator DeepAR.framework so example app links can succeed.
# The vendored DeepAR binary inside deepar_flutter_plus is device-only.
set -euo pipefail

IOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REAL_FRAMEWORK="${IOS_DIR}/.symlinks/plugins/deepar_flutter_plus/ios/DeepAR.framework"
SRC_DIR="${IOS_DIR}/DeepARSimulator/src"
OUT_DIR="${IOS_DIR}/DeepARSimulator/DeepAR.framework"

if [[ ! -f "${REAL_FRAMEWORK}/Headers/DeepAR.h" ]]; then
  echo "error: DeepAR headers not found at ${REAL_FRAMEWORK}" >&2
  echo "Run flutter pub get from the example app before pod install." >&2
  exit 1
fi

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}/Headers" "${OUT_DIR}/Modules"

cp "${REAL_FRAMEWORK}/Headers/DeepAR.h" "${OUT_DIR}/Headers/DeepAR.h"
cp "${REAL_FRAMEWORK}/Headers/CameraController.h" "${OUT_DIR}/Headers/CameraController.h"
cp "${REAL_FRAMEWORK}/Modules/module.modulemap" "${OUT_DIR}/Modules/module.modulemap"

cat > "${OUT_DIR}/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>DeepAR</string>
  <key>CFBundleIdentifier</key>
  <string>ai.deepar.DeepAR.simulator-stub</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>DeepAR</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>0.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>MinimumOSVersion</key>
  <string>14.0</string>
</dict>
</plist>
EOF

SDKROOT="$(xcrun --sdk iphonesimulator --show-sdk-path)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

build_arch() {
  local arch="$1"
  xcrun --sdk iphonesimulator clang \
    -arch "${arch}" \
    -isysroot "${SDKROOT}" \
    -mios-simulator-version-min=14.0 \
    -fobjc-arc \
    -w \
    -fno-modules \
    -I "${OUT_DIR}/Headers" \
    -dynamiclib \
    -install_name @rpath/DeepAR.framework/DeepAR \
    -compatibility_version 1.0 \
    -current_version 1.0 \
    -framework Foundation \
    -framework UIKit \
    -framework AVFoundation \
    -framework CoreMedia \
    -o "${TMP_DIR}/DeepAR-${arch}" \
    "${SRC_DIR}/DeepARStub.m" \
    "${SRC_DIR}/DeepARProtocol.m"
}

build_arch arm64
if build_arch x86_64; then
  lipo -create -output "${OUT_DIR}/DeepAR" "${TMP_DIR}/DeepAR-arm64" "${TMP_DIR}/DeepAR-x86_64"
else
  cp "${TMP_DIR}/DeepAR-arm64" "${OUT_DIR}/DeepAR"
fi

codesign --force --sign - "${OUT_DIR}"
echo "Built simulator DeepAR stub at ${OUT_DIR}"
