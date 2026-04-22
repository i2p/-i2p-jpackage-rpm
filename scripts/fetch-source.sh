#!/bin/bash
# Download and verify the I2P source tarball
set -euo pipefail

VERSION="${1:?Usage: $0 <version> (e.g., 2.7.0)}"
DEST_DIR="${2:-$(pwd)}"

TARBALL="i2psource_${VERSION}.tar.bz2"
PRIMARY_URL="https://files.i2p-projekt.de/${VERSION}/${TARBALL}"
FALLBACK_URL="https://github.com/i2p/i2p.i2p/releases/download/i2p-${VERSION}/${TARBALL}"

echo "Downloading I2P ${VERSION} source tarball..."
echo "  Primary URL: ${PRIMARY_URL}"

if ! curl -fSL -o "${DEST_DIR}/${TARBALL}" "${PRIMARY_URL}"; then
    echo "  Primary download failed, trying GitHub fallback..."
    echo "  Fallback URL: ${FALLBACK_URL}"
    curl -fSL -o "${DEST_DIR}/${TARBALL}" "${FALLBACK_URL}"
fi

if [ ! -s "${DEST_DIR}/${TARBALL}" ]; then
    echo "ERROR: Downloaded file is empty or missing" >&2
    exit 1
fi

echo "Source tarball saved to: ${DEST_DIR}/${TARBALL}"
echo "Size: $(du -h "${DEST_DIR}/${TARBALL}" | cut -f1)"
