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

### ios build_for_testing

```sh
[bundle exec] fastlane ios build_for_testing
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

### ios swiftformatlint

```sh
[bundle exec] fastlane ios swiftformatlint
```

SwiftFormat

### ios lint

```sh
[bundle exec] fastlane ios lint
```

Lint code

### ios preview

```sh
[bundle exec] fastlane ios preview
```

Trigger Preview

### ios buildPreview

```sh
[bundle exec] fastlane ios buildPreview
```

Build Preview

### ios deliverPreview

```sh
[bundle exec] fastlane ios deliverPreview
```

Deliver Preview

### ios production

```sh
[bundle exec] fastlane ios production
```

Trigger Production

### ios buildProduction

```sh
[bundle exec] fastlane ios buildProduction
```

Build Production

### ios deliverProduction

```sh
[bundle exec] fastlane ios deliverProduction
```

Deliver Production

### ios bumpVersion

```sh
[bundle exec] fastlane ios bumpVersion
```

Bump version

### ios updateAppVersion

```sh
[bundle exec] fastlane ios updateAppVersion
```

Update app version

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
