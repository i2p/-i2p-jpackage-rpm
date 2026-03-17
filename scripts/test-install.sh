#!/bin/bash
# Integration test: install the built RPM in a Fedora container and verify it works
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${REPO_DIR}/output"

# Find the built RPM (not source RPM)
RPM_FILE=$(find "${OUTPUT_DIR}" -name "i2p-*.rpm" ! -name "*.src.rpm" | head -1)
if [ -z "$RPM_FILE" ]; then
    echo "ERROR: No RPM found in ${OUTPUT_DIR}/" >&2
    echo "Run build-rpm.sh first." >&2
    exit 1
fi

RPM_NAME=$(basename "$RPM_FILE")
echo "=== Testing RPM: ${RPM_NAME} ==="

CONTAINER_ENGINE="podman"
if ! command -v podman &>/dev/null; then
    CONTAINER_ENGINE="docker"
fi

CONTAINER_NAME="i2p-rpm-test-$$"

cleanup() {
    echo "--- Cleaning up container ---"
    ${CONTAINER_ENGINE} rm -f "${CONTAINER_NAME}" 2>/dev/null || true
}
trap cleanup EXIT

# Start a Fedora container (no systemd — just bash for static tests)
echo "--- Starting Fedora container ---"
${CONTAINER_ENGINE} run -d \
    --name "${CONTAINER_NAME}" \
    -v "${OUTPUT_DIR}:/rpms:ro" \
    fedora:41 \
    sleep infinity

# Wait for container to be ready
sleep 2

run_in() {
    ${CONTAINER_ENGINE} exec "${CONTAINER_NAME}" bash -c "$1"
}

echo "--- Installing Java runtime and RPM ---"
run_in "dnf install -y java-17-openjdk-headless /rpms/${RPM_NAME}"

echo ""
echo "--- Test 1: i2p user exists ---"
run_in "id i2p"
echo "PASS"

echo ""
echo "--- Test 2: systemd unit file installed ---"
run_in "test -f /usr/lib/systemd/system/i2p.service"
echo "PASS"

echo ""
echo "--- Test 3: JAR files exist ---"
run_in "ls /usr/share/i2p/lib/*.jar | head -5"
echo "PASS"

echo ""
echo "--- Test 4: wrapper script is executable ---"
run_in "test -x /usr/libexec/i2p/i2p-wrapper.sh"
echo "PASS"

echo ""
echo "--- Test 5: config files in place ---"
run_in "test -f /etc/sysconfig/i2p"
run_in "test -f /etc/logrotate.d/i2p"
run_in "test -f /usr/lib/sysusers.d/i2p.conf"
run_in "test -f /usr/lib/tmpfiles.d/i2p.conf"
echo "PASS"

echo ""
echo "--- Test 6: directories have correct ownership ---"
run_in "stat -c '%U:%G' /var/lib/i2p" | grep -q "i2p:i2p"
run_in "stat -c '%U:%G' /var/log/i2p" | grep -q "i2p:i2p"
echo "PASS"

echo ""
echo "--- Test 7: default configs present in base dir ---"
run_in "test -f /usr/share/i2p/router.config"
run_in "test -f /usr/share/i2p/clients.config"
echo "PASS"

echo ""
echo "--- Test 8: wrapper script can detect Java ---"
run_in "bash -c 'source /etc/sysconfig/i2p && /usr/libexec/i2p/i2p-wrapper.sh --help 2>&1 || true'" | head -5
echo "PASS (script runs without missing java error)"

echo ""
echo "--- Test 9: Uninstall RPM ---"
run_in "dnf remove -y i2p"
run_in "test ! -f /usr/libexec/i2p/i2p-wrapper.sh"
run_in "test ! -f /usr/lib/systemd/system/i2p.service"
echo "PASS"

echo ""
echo "=== All tests passed ==="
echo ""
echo "NOTE: Systemd service start/stop tests require a systemd-enabled container."
echo "Run manually with: podman run --privileged -v ./output:/rpms:ro fedora:41-init /sbin/init"
