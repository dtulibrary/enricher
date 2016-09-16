use Mix.Config
config :enricher, :solr_fetcher, SolrClient.TestFetcher
config :enricher, :metastore_updater, CommitManager.TestUpdater
config :enricher, :harvest_module, Enricher.ApplicationMock
config :logger, :console,
  level: :error
