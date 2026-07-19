#!/usr/bin/env bash

set -euo pipefail

preferred_device_name="${1:-iPhone 17 Pro}"

runtime_id="$(xcrun simctl list runtimes --json | python3 -c '
import json
import re
import sys

payload = json.load(sys.stdin)
runtimes = [
    runtime
    for runtime in payload.get("runtimes", [])
    if runtime.get("isAvailable", True)
    and runtime.get("identifier", "").startswith("com.apple.CoreSimulator.SimRuntime.iOS-")
]

def version(runtime):
    return tuple(int(part) for part in re.findall(r"\d+", runtime.get("version", "0")))

if not runtimes:
    raise SystemExit("No available iOS Simulator runtime is installed")

print(max(runtimes, key=version)["identifier"])
')"

device_type_id="$(xcrun simctl list devicetypes --json | PREFERRED_DEVICE_NAME="$preferred_device_name" python3 -c '
import json
import os
import re
import sys

payload = json.load(sys.stdin)
preferred = os.environ["PREFERRED_DEVICE_NAME"]
device_types = [
    device_type
    for device_type in payload.get("devicetypes", [])
    if device_type.get("name", "").startswith("iPhone")
]

if not device_types:
    raise SystemExit("No iPhone Simulator device type is installed")

exact = next((item for item in device_types if item.get("name") == preferred), None)
if exact:
    print(exact["identifier"])
    raise SystemExit(0)

def generation(device_type):
    numbers = re.findall(r"\d+", device_type.get("name", ""))
    return tuple(int(number) for number in numbers) if numbers else (0,)

print(max(device_types, key=generation)["identifier"])
')"

simulator_id="$(xcrun simctl list devices --json | RUNTIME_ID="$runtime_id" PREFERRED_DEVICE_NAME="$preferred_device_name" python3 -c '
import json
import os
import sys

payload = json.load(sys.stdin)
runtime_id = os.environ["RUNTIME_ID"]
preferred = os.environ["PREFERRED_DEVICE_NAME"]
devices = [
    device
    for device in payload.get("devices", {}).get(runtime_id, [])
    if device.get("isAvailable", True)
    and device.get("name", "").startswith("iPhone")
]

if not devices:
    raise SystemExit(0)

selected = next((device for device in devices if device.get("name") == preferred), devices[0])
print(selected["udid"])
')"

if [[ -z "$simulator_id" ]]; then
    simulator_id="$(xcrun simctl create "Mira CI iPhone" "$device_type_id" "$runtime_id")"
fi

xcrun simctl boot "$simulator_id" 2>/dev/null || true
xcrun simctl bootstatus "$simulator_id" -b

destination="platform=iOS Simulator,id=$simulator_id"
echo "Prepared $destination"
echo "SIMULATOR_DESTINATION=$destination" >> "${GITHUB_ENV:?GITHUB_ENV must be set}"
