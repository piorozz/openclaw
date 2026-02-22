#!/usr/bin/env bash
# Create an update branch from the latest upstream release (https://github.com/openclaw/openclaw/releases).
# Run from repo root. Requires clean working tree and current branch main.
# You merge the update branch into main yourself when ready.

set -e

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/openclaw/openclaw.git}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
RELEASES_API="${RELEASES_API:-https://api.github.com/repos/openclaw/openclaw/releases/latest}"

# Ensure we're in the repo root (where .git lives)
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "fatal: Not inside a git repository."
  exit 1
}
cd "$GIT_ROOT"

# Require clean main: no merge/rebase in progress
if [[ -f "$GIT_ROOT/.git/MERGE_HEAD" || -d "$GIT_ROOT/.git/rebase-merge" || -d "$GIT_ROOT/.git/rebase-apply" ]]; then
  echo "fatal: Merge or rebase in progress. Finish or abort it first."
  exit 1
fi

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

# Ensure upstream remote exists
if ! git remote get-url "$UPSTREAM_REMOTE" &>/dev/null; then
  echo "Adding remote '$UPSTREAM_REMOTE' -> $UPSTREAM_URL"
  git remote add "$UPSTREAM_REMOTE" "$UPSTREAM_URL"
fi

# Get latest release tag from GitHub
echo "Fetching latest release from GitHub..."
if ! TAG="$(curl -sL "$RELEASES_API" | jq -r .tag_name)" || [[ -z "$TAG" || "$TAG" == "null" ]]; then
  echo "fatal: Could not get latest release (curl/jq or API failed)."
  exit 1
fi
echo "Latest release: $TAG"

echo "Fetching $UPSTREAM_REMOTE tag $TAG..."
git fetch "$UPSTREAM_REMOTE" tag "$TAG"

UPDATE_BRANCH="update/release-$(date +%Y-%m-%d)"
echo "Creating branch '$UPDATE_BRANCH' and merging $TAG..."
git checkout -b "$UPDATE_BRANCH"
if ! git merge --no-ff "$TAG" -m "Merge upstream release $TAG into $UPDATE_BRANCH"; then
  echo ""
  echo "Merge had conflicts. Resolve them, then run:"
  echo "  git add . && git commit --no-edit"
  echo "Then merge this branch into main:"
  echo "  git checkout $DEFAULT_BRANCH && git merge $UPDATE_BRANCH"
  exit 1
fi

echo ""
echo "Update branch '$UPDATE_BRANCH' is ready. To merge into $DEFAULT_BRANCH:"
echo "  git checkout $DEFAULT_BRANCH && git merge $UPDATE_BRANCH"
