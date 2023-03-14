#!/bin/zsh

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

for localizableFile in BundesIdent/Resources/*.lproj/Localizable.strings
do
    sort "$localizableFile" --check &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Sorting file - $localizableFile"
        sort "$localizableFile" -o "$localizableFile"
    fi
done

nvm use --silent
npx git-format-staged --formatter "swiftformat --quiet stdin --stdinpath '{}'" "*.swift"
swiftlint lint --quiet --strict
