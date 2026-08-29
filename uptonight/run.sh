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

# Settings UpTonight reads from the environment. Everything else is written to
# the generated config file below. Elevation is deliberately not exported:
# UpTonight casts ELEVATION with int(), which fails on fractional metres, so it
# goes through the config file where floats are accepted.
while IFS=: read -r option_key env_key; do
    export_option "$option_key" "$env_key"
done <<'EOF'
longitude:LONGITUDE
latitude:LATITUDE
timezone:TIMEZONE
observatory_name:OBSERVATORY_NAME
pressure:PRESSURE
relative_humidity:RELATIVE_HUMIDITY
temperature:TEMPERATURE
observation_date:OBSERVATION_DATE
target_list:TARGET_LIST
type_filter:TYPE_FILTER
output_dir:OUTPUT_DIR
target:TARGET
prefix:PREFIX
EOF

# UpTonight loads its config file with yaml.safe_load(), and YAML is a superset
# of JSON, so the generated config is written as JSON straight from the add-on
# options. Sections that must fall back to UpTonight's own defaults (an unset
# elevation, an unconfigured broker, an empty horizon) are omitted entirely.
write_config_file() {
    if [ ! -f "$OPTIONS_FILE" ]; then
        return 0
    fi

    tmp_file="$(mktemp)"
    trap 'rm -f "$tmp_file"' EXIT

    jq '
        . as $o
        | ($o.features // []) as $enabled
        | (["horizon", "objects", "bodies", "comets", "alttime"]
            | map(. as $feature | {key: $feature, value: ($enabled | index($feature) != null)})
            | from_entries) as $features
        | (($o.elevation // "") | tostring) as $raw_elevation
        | (if ($raw_elevation | test("^-?[0-9]+([.][0-9]+)?$"))
            then ($raw_elevation | tonumber)
            else null end) as $elevation
        | ($o.horizon.anchor_points // []) as $anchor_points
        | ($o.mqtt // {}) as $mqtt
        | {features: $features}
            + (if ($o.layout // "") != "" then {layout: $o.layout} else {} end)
            + (if $o.output_datestamp != null then {output_datestamp: $o.output_datestamp} else {} end)
            + (if ($o.constraints // {}) != {} then {constraints: $o.constraints} else {} end)
            + (if ($o.colors // {}) != {} then {colors: $o.colors} else {} end)
            + (if ($o.live // {}) != {} then {live: $o.live} else {} end)
            + (if $elevation != null then {location: {elevation: $elevation}} else {} end)
            + (if (($o.bucket_list // []) | length) > 0 then {bucket_list: $o.bucket_list} else {} end)
            + (if (($o.done_list // []) | length) > 0 then {done_list: $o.done_list} else {} end)
            + (if (($o.custom_targets // []) | length) > 0 then {custom_targets: $o.custom_targets} else {} end)
            + (if ($mqtt.host // "") != ""
                then {mqtt: ($mqtt | with_entries(select(.value != null and .value != "")))}
                else {} end)
            + (if ($anchor_points | length) >= 2
                then {horizon: {step_size: ($o.horizon.step_size // 5), anchor_points: $anchor_points}}
                else {} end)
    ' "$OPTIONS_FILE" > "$tmp_file"

    if jq -e '((.features // []) | index("horizon") != null)
            and (((.horizon.anchor_points // []) | length) < 2)' "$OPTIONS_FILE" >/dev/null; then
        echo "The horizon feature is enabled but fewer than two anchor points are configured; no horizon will be plotted" >&2
    fi

    mv "$tmp_file" "$CONFIG_FILE"
    trap - EXIT
}

write_config_file

if [ -n "${OUTPUT_DIR:-}" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

exec /app/main "$@"
