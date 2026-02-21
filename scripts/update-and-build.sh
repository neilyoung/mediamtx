#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-and-build.sh --patch-commit <sha> [--tag <vX.Y.Z> | --latest-v1] [--branch-prefix <prefix>] [--output <path>]

Examples:
  scripts/update-and-build.sh --patch-commit abc1234 --tag v1.14.0
  scripts/update-and-build.sh --patch-commit abc1234 --latest-v1

Notes:
  - Requires a clean working tree.
  - Fetches tags from 'origin'.
  - Creates a new branch from the target tag and cherry-picks the patch commit.
USAGE
}

PATCH_COMMIT=""
TARGET_TAG="v1.14.0"
USE_LATEST_V1=false
BRANCH_PREFIX="prod"
OUTPUT_PATH="mediamtx"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --patch-commit)
      PATCH_COMMIT="${2:-}"
      shift 2
      ;;
    --tag)
      TARGET_TAG="${2:-}"
      shift 2
      ;;
    --latest-v1)
      USE_LATEST_V1=true
      shift
      ;;
    --branch-prefix)
      BRANCH_PREFIX="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$PATCH_COMMIT" ]]; then
  echo "Error: --patch-commit is required." >&2
  usage
  exit 1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: not in a git repository." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree is not clean. Commit/stash changes first." >&2
  exit 1
fi

if ! git rev-parse --verify "$PATCH_COMMIT^{commit}" >/dev/null 2>&1; then
  echo "Error: patch commit '$PATCH_COMMIT' not found." >&2
  exit 1
fi

echo "Fetching tags from origin..."
git fetch origin --tags

if [[ "$USE_LATEST_V1" == true ]]; then
  TARGET_TAG="$(git tag --list 'v1.*' --sort=-version:refname | head -n 1)"
  if [[ -z "$TARGET_TAG" ]]; then
    echo "Error: no v1 tags found." >&2
    exit 1
  fi
fi

if ! git rev-parse --verify "$TARGET_TAG^{tag}" >/dev/null 2>&1 && ! git rev-parse --verify "$TARGET_TAG^{commit}" >/dev/null 2>&1; then
  echo "Error: target tag '$TARGET_TAG' not found." >&2
  exit 1
fi

TARGET_BRANCH="${BRANCH_PREFIX}/${TARGET_TAG}-patched"

if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
  echo "Error: branch '$TARGET_BRANCH' already exists." >&2
  echo "Delete it or pass a different --branch-prefix." >&2
  exit 1
fi

echo "Creating branch $TARGET_BRANCH from $TARGET_TAG..."
git switch -c "$TARGET_BRANCH" "$TARGET_TAG"

echo "Cherry-picking patch commit $PATCH_COMMIT..."
if ! git cherry-pick "$PATCH_COMMIT"; then
  echo
  echo "Cherry-pick conflict detected. Resolve conflicts, then run:"
  echo "  git add <files>"
  echo "  git cherry-pick --continue"
  exit 1
fi

echo "Building binary -> $OUTPUT_PATH ..."
go build -o "$OUTPUT_PATH" .

echo

echo "Done."
echo "Branch: $TARGET_BRANCH"
echo "Binary: $OUTPUT_PATH"
