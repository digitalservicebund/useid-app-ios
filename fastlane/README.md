fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios getAppVersion

```sh
[bundle exec] fastlane ios getAppVersion
```

Get App Version

### ios build

```sh
[bundle exec] fastlane ios build
```

Build

### ios test_without_building

```sh
[bundle exec] fastlane ios test_without_building
```

Runs unit tests without building

### ios test

```sh
[bundle exec] fastlane ios test
```

Test

### ios lint

```sh
[bundle exec] fastlane ios lint
```

Lint code

### ios release

```sh
[bundle exec] fastlane ios release
```

Trigger Release

### ios buildRelease

```sh
[bundle exec] fastlane ios buildRelease
```

Build Release

### ios deliverRelease

```sh
[bundle exec] fastlane ios deliverRelease
```

Deliver Release

### ios bumpVersion

```sh
[bundle exec] fastlane ios bumpVersion
```

Bump version

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
