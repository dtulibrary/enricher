use Mix.Config

# For more info about CRON syntax see https://github.com/c-rack/quantum-elixir#crontab-format
# Full run should be done every Saturday at 1am
config :enricher, full_run_schedule: "0 1 * * 6"
# Updates should be run at 4am every morning
config :enricher, update_schedule: "0 4 * * *"
