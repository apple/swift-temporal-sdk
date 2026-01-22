# Auto Release Workflow

This directory contains a reusable GitHub Actions workflow for automated releases based on semantic versioning labels.

## Usage in other repositories

To use this workflow in your repository, create `.github/workflows/auto-release.yml`:

```yaml
name: Auto Release

on:
  schedule:
    - cron: '0 0 * * 1'
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: read

jobs:
  auto-release:
    uses: apple/swift-temporal-sdk/.github/workflows/auto-release.yml@main
```

## How it works

The workflow automatically creates releases by:

1. Analyzing PR labels since the last release
2. Calculating the next version based on semantic versioning labels
3. Creating a GitHub release with auto-generated release notes

## Semantic versioning labels

Each PR should have one of these labels:

- **`semver/none`** - No release needed (e.g., documentation updates, test improvements, CI changes)
- **`🔨 semver/patch`** - Patch release for bug fixes with no public API changes (0.0.1 → 0.0.2)
- **`🆕 semver/minor`** - Minor release for new features that maintain backward compatibility (0.0.1 → 0.1.0)
- **`⚠️ semver/major`** - Major release for breaking changes (0.0.1 → 1.0.0, must be created manually)

When a PR is merged, the automation will:
1. Analyze all merged PRs since the last release
2. Calculate the version bump based on the highest semver impact
3. Automatically create a GitHub release with the newly calculated semantic version tag and generated release notes

Note: The first release and all major releases must be created manually by maintainers.

## Requirements

- Repository must have at least one existing release
- PRs must be labeled with appropriate semver labels
- Repository must have a `main` branch
