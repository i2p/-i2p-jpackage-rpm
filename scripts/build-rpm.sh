#!/bin/bash
# Build I2P RPM package
# Usage: ./scripts/build-rpm.sh [version]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION="${1:-2.7.0}"

echo "=== Building I2P ${VERSION} RPM ==="

# Setup rpmbuild tree
RPMBUILD_DIR="${HOME}/rpmbuild"
rpmdev-setuptree 2>/dev/null || mkdir -p "${RPMBUILD_DIR}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Fetch source tarball
echo "--- Fetching source tarball ---"
"${SCRIPT_DIR}/fetch-source.sh" "${VERSION}" "${RPMBUILD_DIR}/SOURCES"

# Copy packaging sources
echo "--- Copying packaging files ---"
cp "${REPO_DIR}/SOURCES/"* "${RPMBUILD_DIR}/SOURCES/"
cp "${REPO_DIR}/SPEC/i2p.spec" "${RPMBUILD_DIR}/SPECS/"

# Update version in spec file
sed -i "s/^Version:.*/Version:        ${VERSION}/" "${RPMBUILD_DIR}/SPECS/i2p.spec"

# Build RPMs (source + binary)
echo "--- Building RPMs ---"
rpmbuild -ba "${RPMBUILD_DIR}/SPECS/i2p.spec" \
    --define "version ${VERSION}"

# Copy output
OUTPUT_DIR="${REPO_DIR}/output"
mkdir -p "${OUTPUT_DIR}"
find "${RPMBUILD_DIR}/RPMS" -name "*.rpm" -exec cp {} "${OUTPUT_DIR}/" \;
find "${RPMBUILD_DIR}/SRPMS" -name "*.src.rpm" -exec cp {} "${OUTPUT_DIR}/" \;

echo ""
echo "=== Build complete ==="
echo "Output RPMs:"
ls -lh "${OUTPUT_DIR}/"*.rpm
