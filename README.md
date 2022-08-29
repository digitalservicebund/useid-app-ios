# About the project

Securely identify yourself with our app and your ID card anytime, anywhere without video calls and waiting times.

With this Project we aim to develop the state digital identity into a popular and widespread solution - recognised by service providers and citizens.

Digital identification is one of the basic functions necessary for the successful implementation of digital citizen services. For this reason, it must be accessible and usable for all citizens. In this way, we will contribute to increasing the usage rates of digital citizen services.

In our MVP we develop an eID-interface based on the eID-technology to enable the digital identification with the German ID card. From there it will be evolving based on our users’ needs.

## Prerequisites

You will need to install the lasted version of [Xcode](https://developer.apple.com/xcode/) and [homebrew](https://brew.sh).

Afterwards install the command line tools of Xcode:

```sh
xcode-select --install
```

Part of the build process requires some 3rd party tools that you can install using:

```sh
brew bundle install
```

If you want to run [fastlane](https://fastlane.tools) commands you will also need to install our ruby dependencies:

```sh
[sudo] bundle install
```

See the corresponding [readme](fastlane/README.md) for more information about our fastlane setup.


## Getting started

Open the proejct file with Xcode and hit ⌘+R to run the project. Or hit ⌘+U to run all unit and UI tests.


# License

This project is licensed under the [GNU General Public License v3 (GPLv3)](LICENSE).

# Localization

This project uses [Weblate](https://hosted.weblate.org/engage/useid/) for localization. 
