defmodule SolrClient do

  require Logger

  @fetcher Application.get_env(:enricher, :solr_fetcher, SolrClient.Fetcher)
  @journal_defaults %{"q" => "*:*", "fq" => "format:journal", "wt" => "json"}
  @article_query_params %{
    "q" => "format:article",
    "wt" => "json",
    "fl" => "cluster_id_ss, issn_ss, fulltext_list_ssf, access_ss",
    "sort" => "id asc"
  }
  def stack_all_articles(stack_pid) do
    fetch_articles(stack_pid, "*")
  end

  # cursor will be nil when there are no more articles to receive
  def fetch_articles(_, nil) do
    Logger.debug "nil cursor received - exiting"
    :ok
  end

  def fetch_articles(stack_pid, cursor_mark) do
    decoded = article_query_string(cursor_mark) |> @fetcher.get |> decode
    # Transform the documents to Structs and add to the Stack
    cast_to_docs(decoded) |> Enum.each(&Stack.push(stack_pid, &1))
    # Get the next cursor and fetch more articles
    next_cursor = parse_cursor(decoded, cursor_mark)
    fetch_articles(stack_pid, next_cursor)
  end

  # nil when cursor is absent or is the same as current cursor
  # i.e. there are no more results
  defp parse_cursor(response, current_cursor) do
    case Map.get(response, "nextCursorMark") do
      nil -> nil
      ^current_cursor -> nil
      x -> x
    end
  end

  def fetch_journal(identifier, value) do
    journal_query_string(identifier, value)
    |> @fetcher.get
    |> decode
    |> cast_to_journals
    |> hd
  end

  def article_query_string do
    @article_query_params
    |> URI.encode_query
  end

  def article_query_string(cursor_mark) do
    Map.merge(@article_query_params, %{"cursorMark" => cursor_mark})
    |> URI.encode_query
  end

  def journal_query_string(identifier, value) do
    @journal_defaults
    |> Map.merge(%{"q" => "#{identifier}:#{value}"})
    |> URI.encode_query
  end

  def decode(body) do
    {:ok, decoded} = Poison.decode(body)
    decoded
  end

  def cast_to_docs(%{"error" => _msg}), do: nil

  def cast_to_docs(solr_response) do
     get_docs(solr_response)
     |> Enum.map(&SolrDoc.new(&1))
  end

  def cast_to_journals(solr_response) do
    get_docs(solr_response)
    |> Enum.map(&SolrJournal.new(&1))
  end

  defp get_docs(solr_response), do: solr_response["response"]["docs"]

  defmodule Fetcher do
    @metastore_solr Application.get_env(:enricher, :metastore_solr)

    def get(query_string) do
      url = @metastore_solr <> "?" <> query_string
      Logger.debug "fetching #{url}"
      %HTTPoison.Response{body: body} = HTTPoison.get!(url)
      body
    end
  end

  defmodule TestFetcher do
    @journal_response """
    {\"responseHeader\":{\"status\":0,\"QTime\":14,\"params\":{\"q\":\"cluster_id_ss:320735441\",\"wt\":\"json\",\"fq\":\"format:journal\",\"rows\":\"1\"}},\"response\":{\"numFound\":1,\"start\":0,\"maxScore\":17.585644,\"docs\":[{\"access_ss\":[\"dtupub\",\"dtu\"],\"alert_timestamp_dt\":\"2012-11-09T14:17:55.467Z\",\"journal_title_ts\":[\"Power and works engineering\"],\"journal_title_facet\":[\"Power and works engineering\"],\"holdings_ssf\":[\"{\\\"tovolume\\\":\\\"62\\\",\\\"fromyear\\\":\\\"1947\\\",\\\"fromvolume\\\":\\\"42\\\",\\\"toyear\\\":\\\"1967\\\",\\\"alis_key\\\":\\\"000132324\\\",\\\"type\\\":\\\"printed\\\"}\"],\"member_id_ss\":[\"409670022\",\"320735441\"],\"title_ts\":[\"Power and works engineering\"],\"source_ss\":[\"ds1_jnl\",\"jnl_alis\"],\"format\":\"journal\",\"update_timestamp_dt\":\"2014-03-08T19:48:57.715Z\",\"alis_key_ssf\":[\"000132324\"],\"issn_ss\":[\"03702634\"],\"udc_ss\":[\"621.3\",\"621\",\"620.4\",\"(410)\",\"(05)\"],\"fulltext_availability_ss\":[\"UNDETERMINED\"],\"cluster_id_ss\":[\"320735441\"],\"source_id_ss\":[\"ds1_jnl:582772\",\"jnl_alis:000132324\"],\"source_ext_ss\":[\"ds1:ds1_jnl\",\"ds1:jnl_alis\"],\"source_type_ss\":[\"other\"],\"affiliation_associations_json\":\"{\\\"editor\\\":[],\\\"supervisor\\\":[],\\\"author\\\":[]}\",\"id\":\"1392610167\",\"_version_\":1529502580976123905,\"timestamp\":\"2016-03-22T11:48:48.353Z\",\"score\":17.585644}]}}\n
    """
    @all_articles_response """
    {\"responseHeader\":{\"status\":0,\"QTime\":0,\"params\":{\"fl\":\"cluster_id_ss, issn_ss, fulltext_list_ssf, access_ss\",\"sort\":\"id asc\",\"q\":\"format:\\\"article\\\"\",\"cursorMark\":\"*\",\"wt\":\"json\"}},\"response\":{\"numFound\":2708,\"start\":0,\"docs\":[{\"access_ss\":[\"dtupub\",\"dtu\"],\"cluster_id_ss\":[\"2842957\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0908.3349\\\"}\"]},{\"access_ss\":[\"dtupub\",\"dtu\"],\"cluster_id_ss\":[\"3139121\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0801.1253\\\"}\"]},{\"access_ss\":[\"dtupub\",\"dtu\"],\"cluster_id_ss\":[\"3444778\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0710.3111\\\"}\"]},{\"issn_ss\":[\"21511950\",\"21511969\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"scirp\\\",\\\"local\\\":true,\\\"type\\\":\\\"openaccess\\\",\\\"url\\\":\\\"scirp?pi=%2Fjournal%2FPaperDownload.aspx%3FDOI%3D10.4236%2Fjgis.2009.11007&key=193206913\\\"}\"],\"access_ss\":[\"dtupub\",\"dtu\"],\"cluster_id_ss\":[\"84586616\"]},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569811\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.219\\\"}\"]},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569812\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.207\\\"}\"]},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569813\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.226\\\"}\"]},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569814\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.213\\\"}\"]},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569815\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.201\\\"}\"]},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569816\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.203\\\"}\"]}]},\"nextCursorMark\":\"AoEkMTAwNQ==\"}\n
    """
    @empty_articles_response """
    {\"responseHeader\":{\"status\":0,\"QTime\":0,\"params\":{\"sort\":\"id asc\",\"q\":\"issn_ss:\\\"16123174\\\"\",\"cursorMark\":\"AoEkMzgzMg==\",\"wt\":\"json\",\"fq\":\"format:\\\"journal\\\"\"}},\"response\":{\"numFound\":1,\"start\":0,\"docs\":[]},\"nextCursorMark\":\"AoEkMTAwNQ==\"}\n
    """
    # Little bit messy, but we use this method
    # to simulate different Solr responses for different queries
    def get(query_string) do
      Logger.debug query_string
      cond do
        String.contains?(query_string, "AoEkMTAwNQ") -> @empty_articles_response
        String.contains?(query_string, "format%3Aarticle") -> @all_articles_response
        String.contains?(query_string, "issn") -> @journal_response
      end
    end

    def journal_response, do: @journal_response
    def all_articles_response, do: @all_articles_response
  end
end
