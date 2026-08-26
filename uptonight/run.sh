#!/bin/sh
set -eu

OPTIONS_FILE="${UPTONIGHT_OPTIONS_FILE:-/data/options.json}"
CONFIG_FILE="${UPTONIGHT_CONFIG_FILE:-/app/config.yaml}"

export_option() {
    option_key="$1"
    env_key="$2"

    if [ ! -f "$OPTIONS_FILE" ]; then
        return 0
    fi

value="$(jq -r --arg key "$option_key" '.[$key] | select(. != null) | if type == "string" then . elif type == "boolean" then tostring elif type == "number" then tostring else empty end' "$OPTIONS_FILE")"

    if [ -n "$value" ]; then
        export "$env_key=$value"
    fi
}

while IFS=: read -r option_key env_key; do
    export_option "$option_key" "$env_key"
done <<'EOF'
longitude:LONGITUDE
latitude:LATITUDE
elevation:ELEVATION
timezone:TIMEZONE
observatory_name:OBSERVATORY_NAME
pressure:PRESSURE
relative_humidity:RELATIVE_HUMIDITY
temperature:TEMPERATURE
observation_date:OBSERVATION_DATE
target_list:TARGET_LIST
type_filter:TYPE_FILTER
output_dir:OUTPUT_DIR
live_mode:LIVE_MODE
target:TARGET
EOF

write_config_file() {
    if [ ! -f "$OPTIONS_FILE" ]; then
        return 0
    fi

    tmp_file="$(mktemp)"
    trap 'rm -f "$tmp_file"' EXIT

    {
        if jq -e '.features | type == "array"' "$OPTIONS_FILE" >/dev/null; then
            echo "features:"
            for feature in horizon objects bodies comets alttime; do
                if jq -e --arg feature "$feature" '.features | contains([$feature])' "$OPTIONS_FILE" >/dev/null; then
                    echo "  $feature: true"
                else
                    echo "  $feature: false"
                fi
            done
        fi

        horizon_type="$(jq -r '.horizon | if . == null then "null" else type end' "$OPTIONS_FILE")"
        if [ "$horizon_type" = "string" ]; then
            horizon="$(jq -r '.horizon | select(. != "") // empty' "$OPTIONS_FILE")"
            if [ -n "$horizon" ]; then
                printf '%s\n' "$horizon" | awk '
                    {
                        if ($0 ~ /^[[:space:]]/) {
                            next
                        }
                        line = $0
                        sub(/^[[:space:]]*/, "", line)
                        if (line == "" || line ~ /^#/) {
                            next
                        }
                        if (line ~ /^(horizon|step_size|anchor_points|alt|az):([[:space:]]|$)/) {
                            next
                        }
                        exit 1
                    }
                ' || {
                    echo "Invalid horizon YAML: only horizon, step_size, anchor_points, alt, and az keys are supported" >&2
                    exit 1
                }

                if printf '%s\n' "$horizon" | grep -Eq '^[[:space:]]*horizon:'; then
                    printf '%s\n' "$horizon"
                else
                    echo "horizon:"
                    printf '%s\n' "$horizon" | sed 's/^/  /'
                fi
            fi
        elif [ "$horizon_type" = "object" ] && jq -e '.horizon | length > 0' "$OPTIONS_FILE" >/dev/null; then
            jq -e '
                .horizon as $h
                | (($h | keys) - ["step_size", "anchor_points"] | length == 0)
                and (($h.step_size == null) or ($h.step_size | type == "number"))
                and (
                    ($h.anchor_points == null)
                    or (
                        ($h.anchor_points | type == "array")
                        and all($h.anchor_points[];
                            (type == "object")
                            and ((keys - ["az", "alt"]) | length == 0)
                            and has("az")
                            and has("alt")
                            and (.az | type == "number")
                            and (.alt | type == "number")
                        )
                    )
                )
            ' "$OPTIONS_FILE" >/dev/null || {
                echo "Invalid horizon config: horizon must only contain step_size (number) and anchor_points (list of objects that each include numeric az and alt)" >&2
                exit 1
            }

            echo "horizon:"
            if jq -e '.horizon | has("step_size")' "$OPTIONS_FILE" >/dev/null; then
                jq -r '.horizon.step_size | "  step_size: \(.)"' "$OPTIONS_FILE"
            fi
            if jq -e '.horizon.anchor_points | type == "array" and length > 0' "$OPTIONS_FILE" >/dev/null; then
                echo "  anchor_points:"
                jq -r '.horizon.anchor_points[] | "    - az: \(.az)\n      alt: \(.alt)"' "$OPTIONS_FILE"
            fi
        fi
    } > "$tmp_file"

    if [ -s "$tmp_file" ]; then
        mv "$tmp_file" "$CONFIG_FILE"
    else
        rm -f "$tmp_file"
    fi

    trap - EXIT
}

write_config_file

if [ -n "${OUTPUT_DIR:-}" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

exec /app/main "$@"
