#!/usr/bin/env bash
echo "Beginning Release."

TAG_PATTERN="^refs/tags/(.*)$"
SEMVER_PATTERN="^v?((0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(\\-([0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*))?(\\+([0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*))?)$"

if [[ "$GITHUB_REF" =~ $TAG_PATTERN ]]; then
  TAG=${BASH_REMATCH[1]}
else
  echo Cannot create a release from a non-tag >/dev/stderr
  exit 1
fi

# fetch the annotated tag, GHA creates a fake lightweight tag
git fetch origin --force "$GITHUB_REF:$GITHUB_REF" >/dev/null 2>&1

if [[ "$(git describe --match "$(echo "$TAG" | sed 's/./\\&/g')" "$TAG")" != "$TAG" ]]; then
  echo Cannot create a release from a lightweight tag >/dev/stderr
  exit 1
fi

MESSAGE="$(git tag -ln --format "%(contents)" "$TAG")"

if hub release show "$TAG" >/dev/null 2>&1; then
  COMMAND=edit
  ACTION=Editing
else
  COMMAND=create
  ACTION=Creating
fi

echo "$ACTION stable release for tag $TAG"
hub release "$COMMAND" --message "$MESSAGE" "$TAG" >/dev/null
echo "Published $(hub release show --format '%U' "$TAG")"
