use Mix.Config

config :enricher, getit_url: "http://localhost:3000?resolve"
config :enricher, solr_fetcher: SolrClient.TestFetcher
config :enricher, sfx_metadata_api: HoldingsMetadataApi.Test
config :enricher, sfx_file_location: "test/fixtures/institutional_holding.xml"
config :enricher, holdings_fetcher: HoldingsApi.TestFetcher
config :enricher, metastore_solr: "http://test.solr.com/metastore"
