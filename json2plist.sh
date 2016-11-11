#!/bin/sh

# Transform select osrm-text-instructions language files from json to plist
# Depends on osrm-text-instructions git submodule being initialized

cd "./osrm-text-instructions/languages/translations/" || exit 1

for file in ./*; do
    if [ "$file" = "./en.json" ]; then
      LANGUAGE="Base"
    elif [ "$file" = "./zh-Hans.json" ]; then
      LANGUAGE="zh-Hans"
    else
      # skip not-supported languages
      LANGUAGE="skip"
    fi

    if [ "$LANGUAGE" != "skip" ]; then
      LANGUAGE_DIR="${LANGUAGE}.lproj"
      mkdir -p "../../../OSRMTextInstructions/${LANGUAGE_DIR}"
      plutil -convert xml1 "./${file}" -o "../../../OSRMTextInstructions/${LANGUAGE_DIR}/Instructions.plist"
    fi
done

cd - || exit 1
