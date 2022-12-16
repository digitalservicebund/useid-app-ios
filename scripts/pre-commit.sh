#!/bin/zsh
for localizableFile in BundesIdent/Resources/*.lproj/Localizable.strings
do
    echo "Sorting file - $localizableFile"
    sort "$localizableFile" -o "$localizableFile"
done
npx git-format-staged --formatter "swiftformat stdin --stdinpath '{}'" "*.swift"
swiftlint lint --quiet --strict
