# uptonight-ha-app
UpTonight HomeAssistant App Repository

The add-on exposes UpTonight's environment-based configuration as Home Assistant
settings. Leave a setting blank to let UpTonight use its built-in default or a
mounted `config.yaml`; non-empty settings are exported to the upstream app as
the matching environment variables.

Generated files are written to `/config/out` by default, which is the add-on's
Home Assistant-mounted configuration directory. The entrypoint creates the
configured `output_dir` before starting UpTonight.
