use Mix.Config
config :logger,
  backends: [
    {LoggerFileBackend, :debug_log},
    {Enricher.WebLogger, :console}
  ]

config :logger, :debug_log,
   path: "log/debug.log",
   format: "$date $time $level $metadata $levelpad$message\n",
   metadata: [:module, :line],
   level: :debug

