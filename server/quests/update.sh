#!/bin/bash

# Define files to exclude from PEQ updates
EXCLUDED_FILES=(
    "guildlobby/A_Priest_of_Luclin.lua"
    "guildlobby/A_Priestess_of_Luclin.lua"
)

# Fetch latest changes from the remote repository
git fetch origin

# Checkout all updated files from the remote branch except the excluded ones
for file in $(git diff --name-only origin/master); do
    if [[ ! " ${EXCLUDED_FILES[@]} " =~ " ${file} " ]]; then
        git checkout origin/master -- "$file"
    fi
done

echo "Git update completed. The following files were excluded:"
printf "%s\n" "${EXCLUDED_FILES[@]}"
