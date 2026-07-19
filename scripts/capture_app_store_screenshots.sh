#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
developer_dir="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR="$developer_dir"
export PATH="$developer_dir/usr/bin:$PATH"
output_root="${1:-$repo_root/artifacts/app-store-screenshots}"
runtime="${MIRA_SCREENSHOT_RUNTIME:-26.5}"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/mira-screenshots.XXXXXX")"

if ! command -v jq >/dev/null 2>&1; then
    echo "error: jq is required to name exported screenshots" >&2
    exit 1
fi

cleanup() {
    rm -rf "$temporary_root"
}
trap cleanup EXIT

capture_device() {
    local device_name="$1"
    local output_name="$2"
    local result_bundle="$temporary_root/$output_name.xcresult"
    local export_path="$output_root/$output_name"
    local raw_export_path="$temporary_root/$output_name-export"

    mkdir -p "$export_path"

    xcodebuild test \
        -project "$repo_root/Mira.xcodeproj" \
        -scheme "Mira 8" \
        -configuration Release \
        -destination "platform=iOS Simulator,name=$device_name,OS=$runtime" \
        -derivedDataPath "$temporary_root/DerivedData-$output_name" \
        -resultBundlePath "$result_bundle" \
        CODE_SIGNING_ALLOWED=NO \
        ENABLE_TESTABILITY=YES \
        -parallel-testing-enabled NO \
        -only-testing:'Mira 8UITests/MiraAppStoreScreenshotTests'

    xcrun xcresulttool export attachments \
        --path "$result_bundle" \
        --output-path "$raw_export_path"

    while IFS=$'\t' read -r screenshot_name exported_name; do
        cp "$raw_export_path/$exported_name" "$export_path/$screenshot_name.png"
    done < <(
        jq -r '.[] | .attachments[] | select(.suggestedHumanReadableName | endswith(".png")) | [(.suggestedHumanReadableName | sub("_0_[0-9A-F-]+\\.png$"; "")), .exportedFileName] | @tsv' \
            "$raw_export_path/manifest.json" \
            | sort -u
    )
}

capture_device "iPhone 17 Pro Max" "iphone-6.9"
capture_device "iPad Pro 13-inch (M5)" "ipad-13"

echo "App Store screenshot attachments exported to: $output_root"
echo "Each device directory contains five ordered, upload-ready PNG files."
