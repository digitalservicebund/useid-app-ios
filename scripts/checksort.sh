#!/bin/bash
for localizableFile in ../BundesIdent/Resources/*.lproj/Localizable.strings
do
    echo "Check localizable file - $localizableFile"
    sort "$localizableFile" --check
done
