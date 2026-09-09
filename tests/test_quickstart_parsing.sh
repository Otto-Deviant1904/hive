#!/usr/bin/env bash
# Regression test for bash 3.2 empty-field collapse in quickstart.sh
# catalog loader and reader (issue #7339).
set -eo pipefail

# Source the two functions under test from quickstart.sh
source <(sed -n '/^load_model_catalog_rows()/,/^}/p; /^get_preset_field()/,/^}/p' quickstart.sh)

# Simulate catalog_lines: ollama_local has empty model and api_key_env_var
# The Python layer emits __EMPTY__ for empty fields; the bash layer
# converts them back to empty strings in get_preset_field.
catalog_lines="PRESET	ollama_local	ollama	__EMPTY__	16384	131072	__EMPTY__	http://localhost:11434"

MODEL_DEFAULT_ROWS=""
MODEL_CHOICE_ROWS=""
PRESET_ROWS=""
PRESET_MODEL_CHOICE_ROWS=""

while IFS= read -r line; do
    [ -n "$line" ] || continue
    IFS=$'\t' read -r -a _fields <<< "$line"
    row_type="${_fields[0]}"
    if [ "$row_type" = "PRESET" ]; then
        PRESET_ROWS+="${_fields[1]}"$'\t'"${_fields[2]}"$'\t'"${_fields[3]}"$'\t'"${_fields[4]}"$'\t'"${_fields[5]}"$'\t'"${_fields[6]}"$'\t'"${_fields[7]}"$'\n'
    fi
done <<< "$catalog_lines"

result_provider="$(get_preset_field "ollama_local" "provider")"
result_model="$(get_preset_field "ollama_local" "model")"
result_max_tokens="$(get_preset_field "ollama_local" "max_tokens")"
result_api_base="$(get_preset_field "ollama_local" "api_base")"

echo "provider='$result_provider'"
echo "model='$result_model'"
echo "max_tokens='$result_max_tokens'"
echo "api_base='$result_api_base'"

[ "$result_provider" = "ollama" ] || { echo "FAIL: provider"; exit 1; }
[ "$result_model" = "" ] || { echo "FAIL: model should be empty, got '$result_model'"; exit 1; }
[ "$result_max_tokens" = "16384" ] || { echo "FAIL: max_tokens"; exit 1; }
[ "$result_api_base" = "http://localhost:11434" ] || { echo "FAIL: api_base"; exit 1; }

echo "PASS: empty fields preserved correctly"
