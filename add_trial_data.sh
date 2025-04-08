#!/usr/bin/env bash
sfiii3nr1_characters=$(find ./data/sfiii3nr1/trials/base -maxdepth 1 -type d)
for character in $sfiii3nr1_characters; do
    for trial in $(find "$character" -maxdepth 1 -type d); do
        # Check if data.json exists
        if [ -f "$trial/data.json" ]; then
            # Check if trial_name exists and trial_description exists
            cat "$trial/data.json" | jq -e '.trial_name, .trial_description' > /dev/null 2>&1
            if [ $? -ne 0 ]; then
               echo "Error: Missing trial_name or trial_description in $trial/data.json, adding default values."
                # Add default values for trial_name and trial_description
                trial_name=$(basename "$trial")
                cat "$trial/data.json" | jq "{\"trial_name\": \"$trial_name\"} + {\"trial_description\": \"EMPTY\"} + ." > "$trial/data.json.tmp"
                mv "$trial/data.json.tmp" "$trial/data.json"
            fi
        fi
    done
done
