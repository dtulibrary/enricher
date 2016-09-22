use Mix.Config

config :logger,
  backends: [
    {LoggerFileBackend, :prod_log},
    {Enricher.WebLogger, :console_log}
  ]

config :logger, :prod_log,
   path: "log/production.log",
   format: "$date $time $level $metadata $levelpad$message\n",
   metadata: [:module, :line],
   level: :info
