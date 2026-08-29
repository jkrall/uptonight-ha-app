# uptonight-ha-app
UpTonight HomeAssistant App Repository

The add-on image builds UpTonight from the current `main` branch of
`https://github.com/mawinkler/uptonight` during the Docker build, then adds this
repository's Home Assistant entrypoint wrapper. This avoids depending on the
latest published Docker Hub image, but means add-on builds require GitHub access
and may take longer while the upstream app is compiled.

## Configuration

The add-on options cover UpTonight's full configuration surface. Simple text
settings are passed to the app as environment variables; everything else is
rendered into the `config.yaml` UpTonight reads at startup. Leaving a text
setting blank means "use UpTonight's default".

### Location and environment

Option | Type | Default | Notes
------ | ---- | ------- | -----
`longitude` | string | *required* | DMS (`11d34m51.50s`) or decimal degrees
`latitude` | string | *required* | DMS or decimal degrees
`elevation` | string | `0` | Metres above sea level; decimals are allowed
`timezone` | string | `UTC` | TZ name, e.g. `America/Denver`
`observatory_name` | string | `Backyard` | Shown on the plot
`pressure` | string | `0` | Bar; `0` disables refraction correction
`temperature` | string | `0` | Degrees centigrade
`relative_humidity` | string | `0` | Fraction, e.g. `0.7`

### Run and output settings

Option | Type | Default | Notes
------ | ---- | ------- | -----
`observation_date` | string | *tonight* | `MM/DD/YY`
`target_list` | string | `targets/GaryImm` | Also `targets/Messier`, `targets/Herschel400`, `targets/Pensack500`, `targets/OpenNGC`, `targets/OpenIC`, `targets/LBN`, `targets/LDN`. Relative paths resolve inside the add-on's `/app` directory; an absolute path (e.g. under `/homeassistant`) can point at your own list. The `.yaml` suffix is added by UpTonight
`type_filter` | string | *none* | Object type filter, e.g. `Nebula`
`target` | string | *none* | Calculate a single named object only
`prefix` | string | *none* | File name prefix: `uptonight-PREFIX-plot.png`
`output_dir` | string | `/homeassistant/www/uptonight` | Absolute path inside the container
`output_datestamp` | bool | `false` | Add a datestamp to output file names
`layout` | list | `landscape` | `landscape` or `portrait`
`features` | list | `objects`, `bodies` | Any of `horizon`, `objects`, `bodies`, `comets`, `alttime`
`live.enabled` | bool | `false` | Live plot mode; writes `uptonight-liveplot.png` only
`live.interval` | int | `900` | Seconds between live recalculations

### Constraints

`constraints` mirrors UpTonight's constraint block and defaults to UpTonight's
own values: `altitude_constraint_min` (30), `altitude_constraint_max` (80),
`airmass_constraint` (2), `size_constraint_min` (10), `size_constraint_max`
(300), `moon_separation_min` (45), `moon_separation_use_illumination` (true),
`fraction_of_time_observable_threshold` (0.5), `max_number_within_threshold`
(60), and `north_to_east_ccw` (false).

### Plot colors

`colors` accepts the eight plot colors as `#RRGGBB` values: `ticks`, `grid`,
`axes`, `figure`, `legend`, `alttime`, `meridian`, and `text`.

### Target lists

`bucket_list` always includes the named objects, ignoring the constraints, and
`done_list` always excludes them. Both take the object names as they appear in
the selected target list:

```yaml
bucket_list:
  - IC 434
  - NGC 2359
done_list:
  - IC 1795
```

`custom_targets` adds objects that are not in any target list. `name`, `ra`, and
`dec` are required; `description`, `type`, `constellation`, `size`, and `mag`
are optional:

```yaml
custom_targets:
  - name: NGC 4395
    description: NGC 4395
    type: Galaxy
    constellation: Canes Venatici
    size: 13
    ra: 12 25 48
    dec: "+33 32 48"
    mag: 10.0
```

### Custom horizon

Set `horizon` to a mapping with `step_size` and `anchor_points`; every anchor
point needs numeric `az` and `alt` values. Anchor points should start at an
azimuth of 0 and end at 360 so the whole sky is covered, and at least two are
needed before a horizon is plotted:

```yaml
horizon:
  step_size: 5
  anchor_points:
    - az: 0
      alt: 20
    - az: 180
      alt: 15
    - az: 360
      alt: 20
```

Leave `anchor_points` empty (`[]`) to skip the custom horizon. Add `horizon` to
`features` to draw it.

### MQTT

Setting `mqtt.host` publishes the results and the plot to a broker, with Home
Assistant discovery for the created sensor and camera. `port` (1883), `clientid`
(`uptonight`), `user`, and `password` are optional; leave `mqtt.host` blank to
disable publishing. UpTonight only publishes in one-time mode, so MQTT and
`live.enabled` do not combine. When publishing, keep
`constraints.max_number_within_threshold` around 45 — Home Assistant limits the
size of sensor attributes.

## Output

Generated files are written to `/homeassistant/www/uptonight` by default, which
maps to Home Assistant's `www/uptonight` directory. The entrypoint creates the
configured `output_dir` before starting UpTonight. Files in this directory are
served by Home Assistant under `/local/uptonight/`.

## Upgrading

- **0.2.0** replaced the `live_mode` string with the `live` mapping
  (`enabled` / `interval`); the old option is ignored. Everything else is
  additive.
- **0.1.7** changed `horizon` from a YAML *string* to a mapping, so an existing
  `horizon: ""` has to be replaced with the mapping shown above before the
  settings will save.
