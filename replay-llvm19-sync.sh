#!/usr/bin/env bash
#
# replay-llvm19-sync.sh
#
# Replays the LLVM 19 sync fixes from the claude/setup-libcxx-sync-5kWRI
# branch onto a target libcpp checkout (standalone or inside a monorepo
# subdirectory).
#
# Usage:
#   ./replay-llvm19-sync.sh <target-libcpp-dir> [--prefix=<subdir>] [--squash]
#
# Examples:
#   # Standalone libcpp checkout
#   ./replay-llvm19-sync.sh ~/projects/libcpp
#
#   # Inside a monorepo where libcpp lives at third_party/libcpp
#   ./replay-llvm19-sync.sh ~/monorepo --prefix=third_party/libcpp
#
#   # Squash all four commits into one before applying
#   ./replay-llvm19-sync.sh ~/monorepo --prefix=third_party/libcpp --squash
#
# Prerequisites:
#   - Target must be a clean git working tree (no uncommitted changes)
#   - Target libcpp must already be at the "vendored LLVM 19" state
#     (i.e. commit 90535f2 "Replace libcxx/libcxxabi submodules with
#     vendored copy from LLVM monorepo" or equivalent)

set -euo pipefail

SOURCE_BRANCH="claude/setup-libcxx-sync-5kWRI"
BASE_COMMIT="90535f2"  # vendored LLVM 19 copy — fixes apply on top of this

# The four commits to replay, in order. Skip the docs commit by default.
COMMITS=(
  "b19ee97"  # Update build system and overlay files for LLVM 19 compatibility
  "85e78b0"  # Add _LIBCPP_HARDENING_MODE_DEFAULT to config site template
  "9cae389"  # Fix atomic_support.h include paths and Meson configure_file handling
  # "de83fa3"  # docs — uncomment to include concerns-and-next-steps.md
)

SOURCE_REPO="$(git rev-parse --show-toplevel)"

usage() {
  sed -n '2,/^set -e/p' "$0" | sed 's/^# \{0,1\}//;/^set -e/d'
  exit 1
}

TARGET=""
PREFIX=""
SQUASH=0

for arg in "$@"; do
  case "$arg" in
    --prefix=*) PREFIX="${arg#--prefix=}" ;;
    --squash)   SQUASH=1 ;;
    -h|--help)  usage ;;
    -*)         echo "Unknown option: $arg" >&2; usage ;;
    *)          TARGET="$arg" ;;
  esac
done

[[ -z "$TARGET" ]] && usage
[[ ! -d "$TARGET/.git" ]] && { echo "Error: $TARGET is not a git repository" >&2; exit 1; }

# Verify target is clean
if ! git -C "$TARGET" diff-index --quiet HEAD --; then
  echo "Error: target repository has uncommitted changes" >&2
  exit 1
fi

# Verify source branch exists
if ! git -C "$SOURCE_REPO" rev-parse --verify "$SOURCE_BRANCH" >/dev/null 2>&1; then
  echo "Error: branch $SOURCE_BRANCH not found in $SOURCE_REPO" >&2
  exit 1
fi

PATCH_DIR="$(mktemp -d)"
trap 'rm -rf "$PATCH_DIR"' EXIT

echo "==> Generating patches from $SOURCE_REPO ($SOURCE_BRANCH)"
if [[ $SQUASH -eq 1 ]]; then
  # One squashed patch covering all listed commits
  FIRST="${COMMITS[0]}"
  LAST="${COMMITS[-1]}"
  git -C "$SOURCE_REPO" diff "${FIRST}^..${LAST}" > "$PATCH_DIR/0001-llvm19-sync.patch"
  echo "    Created 1 squashed patch"
else
  i=1
  for sha in "${COMMITS[@]}"; do
    git -C "$SOURCE_REPO" format-patch -1 "$sha" \
      --stdout > "$PATCH_DIR/$(printf '%04d' $i)-${sha}.patch"
    i=$((i+1))
  done
  echo "    Created ${#COMMITS[@]} patches"
fi

echo "==> Applying to $TARGET${PREFIX:+ (prefix: $PREFIX)}"
cd "$TARGET"

AM_ARGS=()
[[ -n "$PREFIX" ]] && AM_ARGS+=("--directory=$PREFIX")

if [[ $SQUASH -eq 1 ]]; then
  # Squashed = plain diff, use git apply + manual commit
  APPLY_ARGS=()
  [[ -n "$PREFIX" ]] && APPLY_ARGS+=("--directory=$PREFIX")
  git apply --index "${APPLY_ARGS[@]}" "$PATCH_DIR"/0001-llvm19-sync.patch
  git commit -m "Sync libcpp to LLVM 19.1.7 (build fixes)

Replays commits ${COMMITS[*]} from $SOURCE_BRANCH:
- Update build system and overlay files for LLVM 19 compatibility
- Add _LIBCPP_HARDENING_MODE_DEFAULT to config site template
- Fix atomic_support.h include paths and Meson configure_file handling"
else
  for patch in "$PATCH_DIR"/*.patch; do
    echo "    Applying $(basename "$patch")"
    if ! git am "${AM_ARGS[@]}" "$patch"; then
      echo "" >&2
      echo "Error: failed to apply $patch" >&2
      echo "Resolve conflicts in $TARGET, then run:" >&2
      echo "  git -C $TARGET am --continue" >&2
      echo "Or abort with:" >&2
      echo "  git -C $TARGET am --abort" >&2
      exit 1
    fi
  done
fi

echo ""
echo "==> Done. Review with:"
echo "    git -C $TARGET log --oneline -5"
