defmodule SolrClient do

  @fetcher Application.get_env(:enricher, :solr_fetcher, SolrClient.Fetcher)

  def fetch_journal(identifier, value) do
    journal_query_string(identifier, value)
    |> @fetcher.get
    |> decode
    |> cast_to_docs
    |> hd
  end

  @journal_defaults %{"q" => "*:*", "fq" => "format:journal", "wt" => "json"}

  def journal_query_string(identifier, value) do
    @journal_defaults
    |> Map.merge(%{"q" => "#{identifier}:#{value}"})
    |> URI.encode_query
  end

  def decode(body) do
    {:ok, decoded} = Poison.decode(body)
    decoded
  end

  def cast_to_docs(solr_response) do
     docs = solr_response["response"]["docs"]
     Enum.map(docs, &SolrDoc.new(&1))
  end

  defmodule Fetcher do
    @metastore_solr Application.get_env(:enricher, :metastore_solr)

    def get(query_string) do
      url = @metastore_solr <> "?" <> query_string
      %HTTPoison.Response{body: body} = HTTPoison.get!(url)
      body
    end
  end

  defmodule TestFetcher do

    def get(_) do
      "{\"responseHeader\":{\"status\":0,\"QTime\":14,\"params\":{\"q\":\"cluster_id_ss:320735441\",\"wt\":\"json\",\"fq\":\"format:journal\",\"rows\":\"1\"}},\"response\":{\"numFound\":1,\"start\":0,\"maxScore\":17.585644,\"docs\":[{\"access_ss\":[\"dtupub\",\"dtu\"],\"alert_timestamp_dt\":\"2012-11-09T14:17:55.467Z\",\"journal_title_ts\":[\"Power and works engineering\"],\"journal_title_facet\":[\"Power and works engineering\"],\"holdings_ssf\":[\"{\\\"tovolume\\\":\\\"62\\\",\\\"fromyear\\\":\\\"1947\\\",\\\"fromvolume\\\":\\\"42\\\",\\\"toyear\\\":\\\"1967\\\",\\\"alis_key\\\":\\\"000132324\\\",\\\"type\\\":\\\"printed\\\"}\"],\"member_id_ss\":[\"409670022\",\"320735441\"],\"title_ts\":[\"Power and works engineering\"],\"source_ss\":[\"ds1_jnl\",\"jnl_alis\"],\"format\":\"journal\",\"update_timestamp_dt\":\"2014-03-08T19:48:57.715Z\",\"alis_key_ssf\":[\"000132324\"],\"issn_ss\":[\"03702634\"],\"udc_ss\":[\"621.3\",\"621\",\"620.4\",\"(410)\",\"(05)\"],\"fulltext_availability_ss\":[\"UNDETERMINED\"],\"cluster_id_ss\":[\"320735441\"],\"source_id_ss\":[\"ds1_jnl:582772\",\"jnl_alis:000132324\"],\"source_ext_ss\":[\"ds1:ds1_jnl\",\"ds1:jnl_alis\"],\"source_type_ss\":[\"other\"],\"affiliation_associations_json\":\"{\\\"editor\\\":[],\\\"supervisor\\\":[],\\\"author\\\":[]}\",\"id\":\"1392610167\",\"_version_\":1529502580976123905,\"timestamp\":\"2016-03-22T11:48:48.353Z\",\"score\":17.585644}]}}\n"
    end
  end
end
