#!/bin/sh

# Transform select osrm-text-instructions language files from json to plist
git submodule init
git submodule update
cd "./osrm-text-instructions/languages/translations/" || exit 1

for file in ./*; do
    if [ "$file" = "./en.json" ]; then
      LANGUAGE="Base"
    else
      # skip not-supported languages
      LANGUAGE=$(basename $file)
      LANGUAGE=${LANGUAGE%.json}
    fi

    if [ "$LANGUAGE" != "skip" ]; then
      LANGUAGE_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/${LANGUAGE}.lproj"
      mkdir -p "${LANGUAGE_DIR}"
      plutil -convert xml1 "./${file}" -o "${LANGUAGE_DIR}/Instructions.plist"
    fi
done

cd - || exit 1
