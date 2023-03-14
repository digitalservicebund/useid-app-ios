#!/bin/bash
for localizableFile in ../BundesIdent/Resources/*.lproj/Localizable.strings
do
    echo "Check localizable file - $localizableFile"
    sort "$localizableFile" --check
done

for localizableFile in ../BundesIdent/Resources/*.lproj/Localizable.strings
do
    CURRENT_KEYS=`awk -F '[=]' '{ print $1 }' "$localizableFile"`
    if [[ -z "$KEYS" ]]; then
        KEYS=$CURRENT_KEYS;
    elif [[ $KEYS != $CURRENT_KEYS ]]; then
        echo "Not matching keys";
        exit 1;
    fi
done
