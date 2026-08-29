# uptonight-ha-app
UpTonight HomeAssistant App Repository

The add-on image builds UpTonight from the current `main` branch of
`https://github.com/mawinkler/uptonight` during the Docker build, then adds this
repository's Home Assistant entrypoint wrapper. This avoids depending on the
latest published Docker Hub image, but means add-on builds require GitHub access
and may take longer while the upstream app is compiled.

The add-on exposes UpTonight's environment-based configuration as Home Assistant
settings. Leave a setting blank to let UpTonight use its built-in default or a
mounted `config.yaml`; non-empty settings are exported to the upstream app as
the matching environment variables.

The UpTonight `features` settings are exposed as a Home Assistant list. The
default enables `objects` and `bodies`; add `horizon`, `comets`, or `alttime` to
enable those optional features, or remove entries to disable them.

To configure a custom horizon, set the `horizon` option to a mapping with
`step_size` and `anchor_points`; every anchor point needs numeric `az` and `alt`
values. Anchor points should start at an azimuth of 0 and end at 360 so the
whole sky is covered:

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

Leave `anchor_points` empty (`[]`) to skip the custom horizon. Earlier versions
of this add-on took `horizon` as a YAML *string*; that form is no longer
accepted, so an existing `horizon: ""` (or a quoted YAML block) has to be
replaced with the mapping above before the settings will save.

Generated files are written to `/homeassistant/www/uptonight` by default, which
maps to Home Assistant's `www/uptonight` directory. The entrypoint creates the
configured `output_dir` before starting UpTonight. Files in this directory are
served by Home Assistant under `/local/uptonight/`.
