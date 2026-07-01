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

Generated files are written to `/homeassistant/www/uptonight` by default, which
maps to Home Assistant's `www/uptonight` directory. The entrypoint creates the
configured `output_dir` before starting UpTonight. Files in this directory are
served by Home Assistant under `/local/uptonight/`.
