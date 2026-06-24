#!/bin/sh
set -eu

OPTIONS_FILE="${UPTONIGHT_OPTIONS_FILE:-/data/options.json}"

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

exec /app/main "$@"
