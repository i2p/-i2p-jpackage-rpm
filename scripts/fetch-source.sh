#!/bin/bash
# Download and verify the I2P source tarball
set -euo pipefail

VERSION="${1:?Usage: $0 <version> (e.g., 2.7.0)}"
DEST_DIR="${2:-$(pwd)}"

TARBALL="i2psource_${VERSION}.tar.bz2"
URL="https://github.com/i2p/i2p.i2p/releases/download/i2p-${VERSION}/${TARBALL}"

echo "Downloading I2P ${VERSION} source tarball..."
echo "  URL: ${URL}"

curl -L -o "${DEST_DIR}/${TARBALL}" "${URL}"

if [ ! -s "${DEST_DIR}/${TARBALL}" ]; then
    echo "ERROR: Downloaded file is empty or missing" >&2
    exit 1
fi

echo "Source tarball saved to: ${DEST_DIR}/${TARBALL}"
echo "Size: $(du -h "${DEST_DIR}/${TARBALL}" | cut -f1)"
