#!/bin/bash
#
# build-xcframework.sh
# Genera FeatureFlagsKit.xcframework con slices para dispositivo iOS y simulador.
#
# Uso:  ./build-xcframework.sh
# Salida: ./build/FeatureFlagsKit.xcframework
#
set -euo pipefail

PROJECT="FeatureFlagsKit/FeatureFlagsKit.xcodeproj"
SCHEME="FeatureFlagsKit"
BUILD_DIR="$(pwd)/build"
ARCHIVE_DIR="${BUILD_DIR}/archives"
OUTPUT="${BUILD_DIR}/FeatureFlagsKit.xcframework"

rm -rf "${BUILD_DIR}"
mkdir -p "${ARCHIVE_DIR}"

echo "▸ Archivando para dispositivo iOS…"
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "generic/platform=iOS" \
    -archivePath "${ARCHIVE_DIR}/ios.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -quiet

echo "▸ Archivando para simulador iOS…"
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${ARCHIVE_DIR}/ios-simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -quiet

echo "▸ Empaquetando el .xcframework…"
xcodebuild -create-xcframework \
    -framework "${ARCHIVE_DIR}/ios.xcarchive/Products/Library/Frameworks/FeatureFlagsKit.framework" \
    -framework "${ARCHIVE_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/FeatureFlagsKit.framework" \
    -output "${OUTPUT}"

echo "✅ Generado: ${OUTPUT}"
