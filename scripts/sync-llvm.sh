#!/usr/bin/env bash
# sync-llvm.sh - Sync libcxx and libcxxabi from the LLVM monorepo
#
# Usage: ./scripts/sync-llvm.sh [TAG]
#   TAG defaults to llvmorg-19.1.7
#
# Downloads the LLVM monorepo tarball for the given tag and extracts
# only the libcxx/ and libcxxabi/ directories into the repo root.
# The tarball is streamed through tar so the full archive is never
# written to disk.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TAG="${1:-llvmorg-19.1.7}"
TARBALL_URL="https://github.com/llvm/llvm-project/archive/refs/tags/${TAG}.tar.gz"

# GitHub tarballs extract with this prefix
ARCHIVE_PREFIX="llvm-project-${TAG}"

echo "==> Syncing libcxx and libcxxabi from LLVM tag: ${TAG}"
echo "    Source: ${TARBALL_URL}"

# Clean existing vendored directories
echo "==> Removing existing libcxx/ and libcxxabi/ directories..."
rm -rf "${REPO_ROOT}/libcxx" "${REPO_ROOT}/libcxxabi"

# Download and extract only the needed directories
echo "==> Downloading and extracting (this may take a moment)..."
curl -fSL "$TARBALL_URL" | tar xz \
    -C "$REPO_ROOT" \
    --strip-components=1 \
    "${ARCHIVE_PREFIX}/libcxx" \
    "${ARCHIVE_PREFIX}/libcxxabi"

# Write version tracking file
cat > "${REPO_ROOT}/LLVM_VERSION" <<EOF
tag: ${TAG}
synced: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
source: ${TARBALL_URL}
EOF

echo "==> Wrote ${REPO_ROOT}/LLVM_VERSION"

# Validate key files
echo "==> Validating extraction..."
MISSING=0
for f in \
    libcxx/src/algorithm.cpp \
    libcxx/include/__config \
    libcxxabi/src/cxa_aux_runtime.cpp \
    libcxxabi/include/cxxabi.h \
    libcxxabi/include/__cxxabi_config.h; do
    if [ ! -f "${REPO_ROOT}/${f}" ]; then
        echo "    ERROR: Expected file ${f} not found!" >&2
        MISSING=1
    fi
done

if [ "$MISSING" -ne 0 ]; then
    echo "==> Sync FAILED: some expected files are missing." >&2
    exit 1
fi

echo "==> Successfully synced libcxx and libcxxabi from LLVM ${TAG}"
