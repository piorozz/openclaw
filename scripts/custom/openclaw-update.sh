#!/usr/bin/env bash
# Sync upstream openclaw/openclaw into a new branch so you can merge into main.
# Run from repo root. Requires clean working tree and current branch main.

set -e

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/openclaw/openclaw.git}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

# Ensure we're in the repo root (where .git lives)
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "fatal: Not inside a git repository."
  exit 1
}
cd "$GIT_ROOT"

# Ensure upstream remote exists
if ! git remote get-url "$UPSTREAM_REMOTE" &>/dev/null; then
  echo "Adding remote '$UPSTREAM_REMOTE' -> $UPSTREAM_URL"
  git remote add "$UPSTREAM_REMOTE" "$UPSTREAM_URL"
fi

echo "Fetching $UPSTREAM_REMOTE $UPSTREAM_BRANCH..."
git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"

# Require clean working tree
if [[ -n "$(git status --porcelain)" ]]; then
  echo "fatal: Working tree has uncommitted changes. Commit or stash them, then run again."
  exit 1
fi

# Require we're on default branch (main)
CURRENT="$(git branch --show-current)"
if [[ "$CURRENT" != "$DEFAULT_BRANCH" ]]; then
  echo "fatal: Current branch is '$CURRENT'. Please switch to '$DEFAULT_BRANCH' and run again."
  exit 1
fi

SYNC_BRANCH="sync/upstream-$(date +%Y-%m-%d)"
echo "Creating branch '$SYNC_BRANCH' and merging $UPSTREAM_REMOTE/$UPSTREAM_BRANCH..."
git checkout -b "$SYNC_BRANCH"
if ! git merge --no-ff "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" -m "Merge upstream openclaw into $SYNC_BRANCH"; then
  echo ""
  echo "Merge had conflicts. Resolve them, then run:"
  echo "  git add . && git commit --no-edit"
  echo "Then merge this branch into main:"
  echo "  git checkout $DEFAULT_BRANCH && git merge $SYNC_BRANCH"
  exit 1
fi

echo ""
echo "Sync branch '$SYNC_BRANCH' is ready. To merge into $DEFAULT_BRANCH:"
echo "  git checkout $DEFAULT_BRANCH && git merge $SYNC_BRANCH"
