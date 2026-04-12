#!/usr/bin/env bash
#
# migrate-to-llvm19.sh
#
# Takes a libcpp checkout at the pre-sync state (with libcxx/libcxxabi
# as git submodules pointing at the defunct llvm-mirror repos) and
# migrates it to the fully-working LLVM 19.1.7 vendored state, including
# all build-system fixes.
#
# Works for both standalone libcpp checkouts and monorepos where libcpp
# lives at a subdirectory with libcxx/libcxxabi registered as real
# submodules at that subdirectory.
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
#   ./migrate-to-llvm19.sh <target-repo-dir> [--prefix=<subdir>] [--tag=llvmorg-19.1.7]
#
# Examples:
#   # Standalone libcpp checkout
#   ./migrate-to-llvm19.sh ~/projects/libcpp
#
#   # Monorepo where libcpp lives at third_party/libcpp
#   ./migrate-to-llvm19.sh ~/monorepo --prefix=third_party/libcpp
#
# Prerequisites:
#   - Target is a clean git tree
#   - Target has libcxx / libcxxabi registered as submodules (at <prefix>
#     if --prefix is given)
#   - curl, tar, git available
#   - Network access to github.com

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
PREFIX=""
TAG="$DEFAULT_TAG"

for arg in "$@"; do
  case "$arg" in
    --prefix=*) PREFIX="${arg#--prefix=}" ;;
    --tag=*)    TAG="${arg#--tag=}" ;;
    -h|--help)  usage ;;
    -*)         echo "Unknown option: $arg" >&2; usage ;;
    *)          TARGET="$arg" ;;
  esac
done

[[ -z "$TARGET" ]] && usage
TARGET="$(cd "$TARGET" && pwd)"
[[ ! -d "$TARGET/.git" ]] && { echo "Error: $TARGET is not a git repository" >&2; exit 1; }

# Normalize prefix: strip leading/trailing slashes
PREFIX="${PREFIX#/}"
PREFIX="${PREFIX%/}"

# Full path to the libcpp subdirectory (or target root if no prefix)
LIBCPP_DIR="$TARGET${PREFIX:+/$PREFIX}"
[[ ! -d "$LIBCPP_DIR" ]] && { echo "Error: $LIBCPP_DIR does not exist" >&2; exit 1; }

# Paths relative to the monorepo/repo root (used for git commands)
LIBCXX_PATH="${PREFIX:+$PREFIX/}libcxx"
LIBCXXABI_PATH="${PREFIX:+$PREFIX/}libcxxabi"

if ! git -C "$TARGET" diff-index --quiet HEAD --; then
  echo "Error: target repository has uncommitted changes" >&2
  exit 1
fi

# Sanity: this is a libcpp checkout at the expected location
if [[ ! -f "$LIBCPP_DIR/meson.build" ]] || ! grep -q "libcxx" "$LIBCPP_DIR/meson.build" 2>/dev/null; then
  echo "Error: $LIBCPP_DIR does not look like a libcpp checkout (no meson.build with libcxx references)" >&2
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
# Step 1: Remove libcxx / libcxxabi submodules
# ---------------------------------------------------------------------------
echo "==> Step 1: Removing submodules at $LIBCXX_PATH and $LIBCXXABI_PATH"

# Find submodule name (may differ from path) by scanning .gitmodules
submodule_name_for_path() {
  local path="$1"
  [[ -f .gitmodules ]] || { echo ""; return; }
  git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | \
    awk -v p="$path" '$2 == p { sub(/\.path$/, "", $1); sub(/^submodule\./, "", $1); print $1; exit }'
}

remove_submodule_at() {
  local path="$1"
  local name
  name="$(submodule_name_for_path "$path")"

  if [[ -n "$name" ]]; then
    echo "    deinit + rm submodule: $path (name: $name)"
    git submodule deinit -f -- "$path" 2>/dev/null || true
    git rm -f "$path" 2>/dev/null || rm -rf "$path"
    rm -rf ".git/modules/$name"
    # Also try the path as a module dir (common when name == path)
    rm -rf ".git/modules/$path"
  elif [[ -e "$path" ]]; then
    echo "    $path exists but is not a registered submodule — removing"
    rm -rf "$path"
  else
    echo "    $path: nothing to remove"
  fi
}

remove_submodule_at "$LIBCXX_PATH"
remove_submodule_at "$LIBCXXABI_PATH"

# If .gitmodules is now empty of [submodule] sections, remove it
if [[ -f .gitmodules ]]; then
  if ! grep -q '^\[submodule ' .gitmodules 2>/dev/null; then
    echo "    .gitmodules has no remaining submodule sections — removing"
    git rm -f .gitmodules 2>/dev/null || rm -f .gitmodules
  else
    echo "    .gitmodules still has other submodules — leaving in place"
    git add .gitmodules
  fi
fi

# ---------------------------------------------------------------------------
# Step 2: Download and extract libcxx + libcxxabi into the libcpp dir
# ---------------------------------------------------------------------------
echo "==> Step 2: Vendoring libcxx + libcxxabi from LLVM tag $TAG into $LIBCPP_DIR"

TARBALL_URL="https://github.com/llvm/llvm-project/archive/refs/tags/${TAG}.tar.gz"
ARCHIVE_PREFIX="llvm-project-${TAG}"

echo "    Streaming $TARBALL_URL (this may take a moment)"
curl -fSL "$TARBALL_URL" | tar xz \
  -C "$LIBCPP_DIR" \
  --strip-components=1 \
  "${ARCHIVE_PREFIX}/libcxx" \
  "${ARCHIVE_PREFIX}/libcxxabi"

# Validate extraction (paths are inside LIBCPP_DIR)
MISSING=0
for f in \
  libcxx/src/algorithm.cpp \
  libcxx/include/__config \
  libcxxabi/src/cxa_aux_runtime.cpp \
  libcxxabi/include/cxxabi.h \
  libcxxabi/include/__cxxabi_config.h; do
  if [[ ! -f "$LIBCPP_DIR/$f" ]]; then
    echo "    ERROR: expected file $f not found after extraction" >&2
    MISSING=1
  fi
done
[[ $MISSING -ne 0 ]] && { echo "==> Vendoring FAILED" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Step 3: Write LLVM_VERSION and scripts/sync-llvm.sh inside libcpp dir
# ---------------------------------------------------------------------------
echo "==> Step 3: Writing LLVM_VERSION and scripts/sync-llvm.sh"

cat > "$LIBCPP_DIR/LLVM_VERSION" <<EOF
tag: ${TAG}
synced: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
source: ${TARBALL_URL}
EOF

mkdir -p "$LIBCPP_DIR/scripts"
cat > "$LIBCPP_DIR/scripts/sync-llvm.sh" <<'SYNC_EOF'
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
chmod +x "$LIBCPP_DIR/scripts/sync-llvm.sh"

# ---------------------------------------------------------------------------
# Step 4: Commit the vendoring
# ---------------------------------------------------------------------------
echo "==> Step 4: Committing vendored LLVM $TAG"

# Stage everything under the libcpp dir (or whole repo if no prefix)
if [[ -n "$PREFIX" ]]; then
  git add -A -- "$PREFIX"
  # Also stage .gitmodules change if any
  [[ -f .gitmodules ]] && git add .gitmodules || true
else
  git add -A
fi

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

AM_ARGS=()
[[ -n "$PREFIX" ]] && AM_ARGS+=("--directory=$PREFIX")

for patch in "$PATCH_DIR"/*.patch; do
  echo "    Applying $(basename "$patch")"
  if ! git am "${AM_ARGS[@]}" "$patch"; then
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
if [[ -n "$PREFIX" ]]; then
  echo "    (cd $PREFIX && ./scripts/sync-llvm.sh llvmorg-X.Y.Z)"
else
  echo "    ./scripts/sync-llvm.sh llvmorg-X.Y.Z"
fi
