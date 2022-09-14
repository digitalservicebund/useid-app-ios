# 3. Branching and merging strategies

Date: 2022-09-14

## Status

Accepted

## Context

We use different git branches in our development infrastructure to work on new features, integrate those into the product and release the product.

## Decision

As our main development branch we use the `main` branch (there is currently no need for a separate `develop` branch). We strive for keeping a linear git history on those branches if possible ([A tidy, linear Git history](https://www.bitsnbites.eu/a-tidy-linear-git-history/) for some rationale), therefor we use fast-forward merges instead of merge commits when merging pull requests if possible. Merges should be done by the author of the pull request by rebasing and/or squashing and fast-forward merging into `main`.

We use a `release` or `hotfix` branch, when preparing a new release. The `release` branch is merged back into `main` when the version was successfully built and uploaded. The `hotfix` branch is merged back into `release` and `main` when the version was successfully built and uploaded.

All commits on `main`, `release` and `hotfix` branches are signed and those branches are protected from rewriting history.

## Consequences

Pull Requests are based on `main` and are merged into `main` by default.

For fast-forward merges we can not use the GitHub UI for merging as this either creates merge commits or alters the signature of commits. Rebase and merge via your favorite git client.