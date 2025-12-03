#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift Temporal SDK open source project
##
## Copyright (c) 2025 Apple Inc. and the Swift Temporal SDK project authors
## Licensed under MIT License
##
## See LICENSE.txt for license information
##
##===----------------------------------------------------------------------===##

set -euo pipefail

# Auto-release script
# This script calculates the next version based on PR labels and creates a GitHub release
#
# Required environment variables:
# - GITHUB_TOKEN: GitHub token with repo permissions
# - GITHUB_REPOSITORY: Repository in format "owner/repo"

# Get the latest release tag
LATEST_TAG=$(gh release list --limit 1 --json tagName --jq '.[0].tagName')

if [ -z "$LATEST_TAG" ]; then
  echo "Error: No previous releases found. Cannot determine version."
  exit 1
fi

echo "Latest release: $LATEST_TAG"
LATEST_TAG_DATE=$(gh release view "$LATEST_TAG" --json publishedAt --jq '.publishedAt')
BASE_REF="$LATEST_TAG"

# Parse current version
if [[ $LATEST_TAG =~ ^v?([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"
else
  echo "Error: Latest tag '$LATEST_TAG' does not match semver format (vX.Y.Z or X.Y.Z)."
  exit 1
fi

echo "Current version: $MAJOR.$MINOR.$PATCH"

# Get all merged PRs since last release
PRS=$(gh pr list --state merged --base main --json number,mergedAt --jq ".[] | select(.mergedAt > \"$LATEST_TAG_DATE\") | .number")

if [ -z "$PRS" ]; then
  # If no PRs found, check for direct commits
  COMMITS=$(git rev-list "${BASE_REF}"..HEAD --count 2>/dev/null || echo "0")
  if [ "$COMMITS" = "0" ]; then
    echo "No changes since last release. Skipping release."
    exit 0
  fi
  echo "Found $COMMITS commits since last release, but no PRs. Creating patch release."
  BUMP_TYPE="patch"
else
  echo "Analyzing PRs since $LATEST_TAG_DATE"
  echo "PRs: $PRS"

  # Determine the highest semver bump needed
  BUMP_TYPE="none"
  RELEASE_NEEDED=false

  for PR in $PRS; do
    LABELS=$(gh pr view "$PR" --json labels --jq '.labels[].name')
    echo "PR #$PR labels: $LABELS"

    if echo "$LABELS" | grep -q "⚠️ semver/major"; then
      echo "Error: ⚠️ semver/major found in PR #$PR. Major releases must be created manually."
      exit 1
    elif echo "$LABELS" | grep -q "🆕 semver/minor"; then
      echo "  -> 🆕 semver/minor found"
      BUMP_TYPE="minor"
      RELEASE_NEEDED=true
    elif echo "$LABELS" | grep -q "🔨 semver/patch"; then
      echo "  -> 🔨 semver/patch found"
      if [ "$BUMP_TYPE" = "none" ]; then
        BUMP_TYPE="patch"
        RELEASE_NEEDED=true
      fi
    elif echo "$LABELS" | grep -q "semver/none"; then
      echo "  -> semver/none found"
    else
      # No semver label found, default to none (no release)
      echo "  -> Warning: No semver label found. Skipping this PR."
    fi
  done

  if [ "$RELEASE_NEEDED" = false ]; then
    echo "No PRs found requiring a release. Skipping release."
    exit 0
  fi
fi

# Calculate new version
case $BUMP_TYPE in
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "No version bump needed"
    exit 0
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
NEW_TAG="$NEW_VERSION"

echo ""
echo "========================================"
echo "Creating new release"
echo "Version: $NEW_VERSION"
echo "Bump type: $BUMP_TYPE"
echo "========================================"
echo ""

# Generate release notes using GitHub API
RELEASE_NOTES=$(gh api "repos/$GITHUB_REPOSITORY/releases/generate-notes" \
  -f tag_name="$NEW_TAG" \
  -f target_commitish="$(git rev-parse HEAD)" \
  -f previous_tag_name="$LATEST_TAG" \
  --jq '.body')

# Create release
echo "Creating GitHub release $NEW_TAG..."
gh release create "$NEW_TAG" \
  --title "$NEW_TAG" \
  --notes "$RELEASE_NOTES" \
  --target "$(git rev-parse HEAD)"

echo ""
echo "Release $NEW_TAG created successfully!"
echo ""
