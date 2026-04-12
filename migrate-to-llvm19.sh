#!/usr/bin/env bash
#
# migrate-to-llvm19.sh
#
# Takes a libcpp checkout at the pre-sync state (with libcxx/libcxxabi
# as git submodules pointing at the defunct llvm-mirror repos) and
# migrates it to the fully-working LLVM 19.1.7 vendored state, including
# all build-system fixes.
#
# This reproduces the full sequence:
#   1. Remove libcxx / libcxxabi submodules
#   2. Vendor libcxx + libcxxabi from llvmorg-19.1.7 via monorepo tarball
#   3. Add scripts/sync-llvm.sh for future re-syncs
#   4. Write LLVM_VERSION tracking file
#   5. Commit the vendoring
#   6. Apply the three build-fix patches from branch
#      claude/setup-libcxx-sync-5kWRI
#
# Usage:
#   ./migrate-to-llvm19.sh <target-libcpp-dir> [--tag=llvmorg-19.1.7]
#
# Prerequisites:
#   - Target is a standalone libcpp git checkout with a clean tree
#   - Target currently has libcxx/ and libcxxabi/ as submodules
#   - curl, tar, git available
#   - Network access to github.com
#
# Monorepo note: if libcpp lives inside a monorepo subdirectory, run
# this script on a standalone checkout first, then merge the result
# into your monorepo with `git subtree pull` or equivalent. Running it
# directly against a monorepo would corrupt submodule state at the
# monorepo root.

set -euo pipefail

DEFAULT_TAG="llvmorg-19.1.7"
SOURCE_REPO="$(git rev-parse --show-toplevel)"
FIX_BRANCH="claude/setup-libcxx-sync-5kWRI"
FIX_COMMITS=(
  "b19ee97"  # Update build system and overlay files for LLVM 19 compatibility
  "85e78b0"  # Add _LIBCPP_HARDENING_MODE_DEFAULT to config site template
  "9cae389"  # Fix atomic_support.h include paths and Meson configure_file handling
)

usage() {
  sed -n '2,/^set -e/p' "$0" | sed 's/^# \{0,1\}//;/^set -e/d'
  exit 1
}

TARGET=""
TAG="$DEFAULT_TAG"

for arg in "$@"; do
  case "$arg" in
    --tag=*)   TAG="${arg#--tag=}" ;;
    -h|--help) usage ;;
    -*)        echo "Unknown option: $arg" >&2; usage ;;
    *)         TARGET="$arg" ;;
  esac
done

[[ -z "$TARGET" ]] && usage
TARGET="$(cd "$TARGET" && pwd)"
[[ ! -d "$TARGET/.git" ]] && { echo "Error: $TARGET is not a git repository" >&2; exit 1; }

if ! git -C "$TARGET" diff-index --quiet HEAD --; then
  echo "Error: target repository has uncommitted changes" >&2
  exit 1
fi

# Sanity: this is a libcpp checkout
if [[ ! -f "$TARGET/meson.build" ]] || ! grep -q "libcxx" "$TARGET/meson.build" 2>/dev/null; then
  echo "Error: $TARGET does not look like a libcpp checkout (no meson.build with libcxx references)" >&2
  exit 1
fi

# Verify we can get the fix patches from the source repo
if ! git -C "$SOURCE_REPO" rev-parse --verify "$FIX_BRANCH" >/dev/null 2>&1; then
  echo "Error: branch $FIX_BRANCH not found in $SOURCE_REPO" >&2
  echo "       Run this script from inside the libcpp checkout that contains the fix branch." >&2
  exit 1
fi

PATCH_DIR="$(mktemp -d)"
trap 'rm -rf "$PATCH_DIR"' EXIT

echo "==> Generating fix patches from $FIX_BRANCH"
i=1
for sha in "${FIX_COMMITS[@]}"; do
  git -C "$SOURCE_REPO" format-patch -1 "$sha" \
    --stdout > "$PATCH_DIR/$(printf '%04d' $i)-${sha}.patch"
  i=$((i+1))
done

cd "$TARGET"

# ---------------------------------------------------------------------------
# Step 1: Remove libcxx / libcxxabi submodules if present
# ---------------------------------------------------------------------------
echo "==> Step 1: Removing libcxx / libcxxabi submodules"

remove_submodule() {
  local name="$1"
  if git config --file .gitmodules --get "submodule.$name.path" >/dev/null 2>&1; then
    echo "    deinit + rm submodule: $name"
    git submodule deinit -f -- "$name" 2>/dev/null || true
    git rm -f "$name" 2>/dev/null || rm -rf "$name"
    rm -rf ".git/modules/$name"
  elif [[ -e "$name" ]]; then
    echo "    $name exists but is not a registered submodule — removing anyway"
    rm -rf "$name"
  fi
}

remove_submodule libcxx
remove_submodule libcxxabi

# If .gitmodules is now empty, remove it
if [[ -f .gitmodules ]] && [[ ! -s .gitmodules || -z "$(grep -v '^[[:space:]]*$' .gitmodules)" ]]; then
  git rm -f .gitmodules 2>/dev/null || rm -f .gitmodules
fi

# ---------------------------------------------------------------------------
# Step 2: Download and extract libcxx + libcxxabi from LLVM monorepo
# ---------------------------------------------------------------------------
echo "==> Step 2: Vendoring libcxx + libcxxabi from LLVM tag $TAG"

TARBALL_URL="https://github.com/llvm/llvm-project/archive/refs/tags/${TAG}.tar.gz"
ARCHIVE_PREFIX="llvm-project-${TAG}"

echo "    Streaming $TARBALL_URL (this may take a moment)"
curl -fSL "$TARBALL_URL" | tar xz \
  --strip-components=1 \
  "${ARCHIVE_PREFIX}/libcxx" \
  "${ARCHIVE_PREFIX}/libcxxabi"

# Validate extraction
MISSING=0
for f in \
  libcxx/src/algorithm.cpp \
  libcxx/include/__config \
  libcxxabi/src/cxa_aux_runtime.cpp \
  libcxxabi/include/cxxabi.h \
  libcxxabi/include/__cxxabi_config.h; do
  if [[ ! -f "$f" ]]; then
    echo "    ERROR: expected file $f not found after extraction" >&2
    MISSING=1
  fi
done
[[ $MISSING -ne 0 ]] && { echo "==> Vendoring FAILED" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Step 3: Write LLVM_VERSION and scripts/sync-llvm.sh
# ---------------------------------------------------------------------------
echo "==> Step 3: Writing LLVM_VERSION and scripts/sync-llvm.sh"

cat > LLVM_VERSION <<EOF
tag: ${TAG}
synced: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
source: ${TARBALL_URL}
EOF

mkdir -p scripts
cat > scripts/sync-llvm.sh <<'SYNC_EOF'
#!/usr/bin/env bash
# sync-llvm.sh - Sync libcxx and libcxxabi from the LLVM monorepo
#
# Usage: ./scripts/sync-llvm.sh [TAG]
#   TAG defaults to llvmorg-19.1.7
#
# Downloads the LLVM monorepo tarball for the given tag and extracts
# only the libcxx/ and libcxxabi/ directories into the repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TAG="${1:-llvmorg-19.1.7}"
TARBALL_URL="https://github.com/llvm/llvm-project/archive/refs/tags/${TAG}.tar.gz"
ARCHIVE_PREFIX="llvm-project-${TAG}"

echo "==> Syncing libcxx and libcxxabi from LLVM tag: ${TAG}"
rm -rf "${REPO_ROOT}/libcxx" "${REPO_ROOT}/libcxxabi"
curl -fSL "$TARBALL_URL" | tar xz \
    -C "$REPO_ROOT" \
    --strip-components=1 \
    "${ARCHIVE_PREFIX}/libcxx" \
    "${ARCHIVE_PREFIX}/libcxxabi"

cat > "${REPO_ROOT}/LLVM_VERSION" <<VER
tag: ${TAG}
synced: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
source: ${TARBALL_URL}
VER

echo "==> Successfully synced libcxx and libcxxabi from LLVM ${TAG}"
SYNC_EOF
chmod +x scripts/sync-llvm.sh

# ---------------------------------------------------------------------------
# Step 4: Commit the vendoring
# ---------------------------------------------------------------------------
echo "==> Step 4: Committing vendored LLVM $TAG"

git add -A
git commit -m "Replace libcxx/libcxxabi submodules with vendored copy from LLVM monorepo

The llvm-mirror GitHub repositories have stopped updating. This replaces
the defunct submodule references with vendored copies extracted directly
from the official LLVM monorepo at tag ${TAG}.

Changes:
- Remove libcxx and libcxxabi git submodules
- Add scripts/sync-llvm.sh for extracting libcxx/libcxxabi from LLVM
  monorepo tarballs at any tag
- Vendor libcxx and libcxxabi from ${TAG}
- Add LLVM_VERSION file tracking the synced tag and date"

# ---------------------------------------------------------------------------
# Step 5: Apply the three fix patches
# ---------------------------------------------------------------------------
echo "==> Step 5: Applying build-system fix patches"

for patch in "$PATCH_DIR"/*.patch; do
  echo "    Applying $(basename "$patch")"
  if ! git am "$patch"; then
    echo "" >&2
    echo "Error: failed to apply $(basename "$patch")" >&2
    echo "Resolve conflicts in $TARGET, then run:" >&2
    echo "  git -C $TARGET am --continue" >&2
    exit 1
  fi
done

echo ""
echo "==> Migration complete. Review with:"
echo "    git -C $TARGET log --oneline -5"
echo ""
echo "==> To re-sync against a newer LLVM tag in the future:"
echo "    ./scripts/sync-llvm.sh llvmorg-X.Y.Z"
