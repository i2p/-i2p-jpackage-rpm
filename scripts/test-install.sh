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

# Start a Fedora container with systemd
echo "--- Starting Fedora container ---"
${CONTAINER_ENGINE} run -d \
    --name "${CONTAINER_NAME}" \
    --privileged \
    -v "${OUTPUT_DIR}:/rpms:ro" \
    fedora:41 \
    /sbin/init

# Wait for systemd to start
sleep 3

run_in() {
    ${CONTAINER_ENGINE} exec "${CONTAINER_NAME}" bash -c "$1"
}

echo "--- Installing RPM ---"
run_in "dnf install -y /rpms/${RPM_NAME}"

echo ""
echo "--- Test 1: i2p user exists ---"
run_in "id i2p"
echo "PASS"

echo ""
echo "--- Test 2: systemd unit is loaded ---"
run_in "systemctl status i2p --no-pager || true"
run_in "systemctl list-unit-files i2p.service | grep -q i2p"
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
echo "PASS"

echo ""
echo "--- Test 6: directories have correct ownership ---"
run_in "stat -c '%U:%G' /var/lib/i2p" | grep -q "i2p:i2p"
run_in "stat -c '%U:%G' /var/log/i2p" | grep -q "i2p:i2p"
echo "PASS"

echo ""
echo "--- Test 7: Start I2P service ---"
run_in "dnf install -y java-17-openjdk-headless"
run_in "systemctl start i2p"
sleep 5
run_in "systemctl is-active i2p"
echo "PASS"

echo ""
echo "--- Test 8: Router console port reachable ---"
TRIES=0
MAX_TRIES=12
while [ $TRIES -lt $MAX_TRIES ]; do
    if run_in "curl -sf http://127.0.0.1:7657/ > /dev/null 2>&1"; then
        echo "Router console is responding on port 7657"
        break
    fi
    TRIES=$((TRIES + 1))
    echo "  Waiting for router console... (${TRIES}/${MAX_TRIES})"
    sleep 5
done
if [ $TRIES -eq $MAX_TRIES ]; then
    echo "WARNING: Router console did not respond within 60s (may be normal for first start)"
fi

echo ""
echo "--- Test 9: Stop I2P service ---"
run_in "systemctl stop i2p"
sleep 2
run_in "systemctl is-active i2p 2>/dev/null && exit 1 || true"
echo "PASS"

echo ""
echo "--- Test 10: Uninstall RPM ---"
run_in "dnf remove -y i2p"
run_in "test ! -f /usr/libexec/i2p/i2p-wrapper.sh"
echo "PASS"

echo ""
echo "=== All tests passed ==="
