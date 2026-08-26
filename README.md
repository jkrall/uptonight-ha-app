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

To configure a custom horizon, paste the UpTonight horizon YAML into the
`horizon` option. You can paste either the value under the upstream `horizon:`
key:

```yaml
step_size: 5
anchor_points:
  - alt: 20
    az: 0
  - alt: 20
    az: 360
```

or include the top-level `horizon:` key from the upstream config example.

Generated files are written to `/homeassistant/www/uptonight` by default, which
maps to Home Assistant's `www/uptonight` directory. The entrypoint creates the
configured `output_dir` before starting UpTonight. Files in this directory are
served by Home Assistant under `/local/uptonight/`.
