# 4. Triggering a release

Date: 2022-09-14

## Status

Accepted

## Context

We need to build and upload new versions of the app and we want to be independent from developer machines to do that.

## Decision

We use GitHub Actions as our CI to build and upload new builds of the app to TestFlight and the App Store.

Release builds are triggered manually via the interface of GitHub in order to have more control over when releases are built and to have the ability to retrigger a release for an old or same commit.

Release builds are build from a `release` branch. The `release` branch is merged when the version has been built and successfully uploaded.

The version number and build number are checked into the repository. When triggering a build, one can specify if the CI should increase the semantic version (major, minor, patch) and/or generate a new build number or leave the version and build number as is.

When a new release is successfully built, a tag with the format %VERSION%-%BUILD_NUMBER% (e.g. 1.4.3-87) is added to the corresponding commit.

## Consequences

None