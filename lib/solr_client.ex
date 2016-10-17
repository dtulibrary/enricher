defmodule SolrClient do

  require Logger

  @fetcher Application.get_env(:enricher, :solr_fetcher, SolrClient.Fetcher)
  @journal_defaults [q: "*:*", fq: "format:journal", facet: "false", wt: "json"]
  @default_query_params [
    q: "*:*",
    fq: "superformat_s:bib",
    wt: "json",
    fl: "id, format, issn_ss, eissn_ss, isbn_ss, fulltext_list_ssf, pub_date_tis, source_ss, journal_title_ts",
    facet: "false",
    sort: "id desc"
  ]

  # We add extra filters to the default set to get our other query types 
  @partial_query_params @default_query_params ++ [fq: "fulltext_availability_ss:UNDETERMINED"]
  @sfx_query_params @default_query_params ++ [fq: "fulltext_info_ss:sfx"]
  @no_access_query_params @default_query_params ++ [fq:  "fulltext_info_ss:none"]

  @all_journals_params [ 
    q: "*:*",
    fq: "format:journal",
    fq: "source_ss:jnl_sfx",
    wt: "json",
    sort: "id asc",
    rows: 100000 
  ]

  def full_update(number, cursor) do
    fetch_docs(@default_query_params, number, cursor) 
  end

  def partial_update(number, cursor) do
    fetch_docs(@partial_query_params, number, cursor) 
  end 

  def sfx_update(number, cursor) do
    fetch_docs(@sfx_query_params, number, cursor) 
  end 

  def no_access_update(number, cursor) do
    fetch_docs(@no_access_query_params, number, cursor) 
  end 

  def make_query_string(default_params, rows, cursor_mark) do
    default_params ++ [cursorMark:  cursor_mark, rows: rows] |> URI.encode_query
  end

  def fetch_docs(query_defaults, rows, cursor_mark) do
    query_string =  make_query_string(query_defaults, rows, cursor_mark)
    decoded = query_string |> @fetcher.get |> decode 
    docs = cast_to_docs(decoded) 
    next_cursor = parse_cursor(decoded, cursor_mark)
    batch_size = batch_size(decoded)
    {docs, next_cursor, batch_size}
  end

  def fetch_article(id, url) do
    @default_query_params
    |> Enum.into(%{})
    |> Map.merge(%{q: "cluster_id_ss:#{id}"}) 
    |> URI.encode_query
    |> @fetcher.simple_get(url)
    |> decode
    |> cast_to_docs
    |> first
  end

  def all_journals do
    @all_journals_params 
    |> URI.encode_query 
    |> @fetcher.get 
    |> decode
    |> cast_to_journals
  end
  
  def all_journals(url) do
    @all_journals_params 
    |> URI.encode_query 
    |> @fetcher.simple_get(url) 
    |> decode
    |> cast_to_journals
  end

  # nil when cursor is absent or is the same as current cursor
  # i.e. there are no more results
  # Otherwise, the cursor for the next result set
  defp parse_cursor(response, current_cursor) do
    case Map.get(response, "nextCursorMark") do
      nil -> nil
      ^current_cursor -> nil
      x -> x
    end
  end

  def batch_size(%{"response" => %{"numFound" => size}}), do: size

  def batch_size(_), do: 0

  def fetch_journal(_identifier, nil), do: nil

  def fetch_journal(identifier, value) do
    journal_query_string(identifier, value)
    |> @fetcher.get
    |> decode
    |> cast_to_journals
    |> first
  end

  def first([]), do: nil
  def first([head|_tail]), do: head

  def journal_query_string(identifier, value) do
    @journal_defaults
    |> Enum.into(%{})
    |> Map.merge(%{"q" => "#{identifier}:#{value}"})
    |> URI.encode_query
  end

  def decode(:error), do: nil
  def decode(nil), do: nil

  def decode(body) do
    case Poison.decode(body) do
      {:ok, json} -> json
      {:error, msg} ->
        Logger.error "Error decoding json: #{inspect msg}"
        Logger.error inspect(body)
        raise "Error decoding json"
    end
  end

  def cast_to_docs(%{"error" => _msg}), do: []

  def cast_to_docs(solr_response) do
     get_docs(solr_response)
     |> Enum.map(&SolrDoc.new(&1))
  end

  def cast_to_journals(solr_response) do
    get_docs(solr_response)
    |> Enum.map(&SolrJournal.new(&1))
  end
  
  # This will catch json parsing errors
  def get_docs(nil), do: []

  # This will intercept Solr server side errors
  def get_docs(%{"error" => %{"code" => code, "msg" => msg}, "responseHeader" => %{"params" => params}}) do
    Logger.error "Solr error #{code}: #{msg}. Params: #{inspect params}"
    []
  end

  def get_docs(solr_response), do: solr_response["response"]["docs"]

  defmodule Fetcher do
    def metastore_solr, do: Enricher.HarvestManager.search_endpoint(Manager)

    def get(query_string, retries \\ 0)
    def get(query_string, 10) do
      Logger.error "Query timed out 10 times! Exiting..."
      Logger.error query_string
      :shutdown
    end

    def get(query_string, retries) do
      url = metastore_solr <> "?" <> query_string
      Logger.debug "Fetching #{url}"
      start_time = DateTime.utc_now |> DateTime.to_unix
      case HTTPoison.get(url, [{"Keep-Alive", "Keep-Alive"}], timeout: 240000, recv_timeout: 240000) do
         {:ok, %HTTPoison.Response{body: body}} ->
           end_time = DateTime.utc_now |> DateTime.to_unix
           Logger.debug "Request took #{start_time - end_time} seconds" 
           body
         {:error, %HTTPoison.Error{reason: reason}} ->
           Logger.error "Error querying #{url} - #{reason}."
           :timer.sleep((retries + 1) * 10000) # Give Solr a break
           get(query_string, retries + 1)
      end
    end

    @doc """
    Allows us to make a query with a specified endpoint
    rather than using the endpoint stored in the 
    HarvestManager's state.
    Useful for debugging.
    """
    def simple_get(query_string, endpoint) do
      url = "#{endpoint}/solr/metastore/toshokan?#{query_string}"
      HTTPoison.get!(url, timeout: 240000, recv_timeout: 240000) |> Map.get(:body)
    end
  end

  defmodule TestFetcher do
    @journal_response """
    {\"responseHeader\":{\"status\":0,\"QTime\":14,\"params\":{\"q\":\"cluster_id_ss:320735441\",\"wt\":\"json\",\"fq\":\"format:journal\",\"rows\":\"1\"}},\"response\":{\"numFound\":1,\"start\":0,\"maxScore\":17.585644,\"docs\":[{\"access_ss\":[\"dtupub\",\"dtu\"],\"alert_timestamp_dt\":\"2012-11-09T14:17:55.467Z\",\"journal_title_ts\":[\"Power and works engineering\"],\"journal_title_facet\":[\"Power and works engineering\"],\"holdings_ssf\":[\"{\\\"tovolume\\\":\\\"62\\\",\\\"fromyear\\\":\\\"1947\\\",\\\"fromvolume\\\":\\\"42\\\",\\\"toyear\\\":\\\"1967\\\",\\\"alis_key\\\":\\\"000132324\\\",\\\"type\\\":\\\"printed\\\"}\"],\"member_id_ss\":[\"409670022\",\"320735441\"],\"title_ts\":[\"Power and works engineering\"],\"source_ss\":[\"ds1_jnl\",\"jnl_alis\"],\"format\":\"journal\",\"update_timestamp_dt\":\"2014-03-08T19:48:57.715Z\",\"alis_key_ssf\":[\"000132324\"],\"issn_ss\":[\"03702634\"],\"udc_ss\":[\"621.3\",\"621\",\"620.4\",\"(410)\",\"(05)\"],\"fulltext_availability_ss\":[\"UNDETERMINED\"],\"cluster_id_ss\":[\"320735441\"],\"source_id_ss\":[\"ds1_jnl:582772\",\"jnl_alis:000132324\"],\"source_ext_ss\":[\"ds1:ds1_jnl\",\"ds1:jnl_alis\"],\"source_type_ss\":[\"other\"],\"affiliation_associations_json\":\"{\\\"editor\\\":[],\\\"supervisor\\\":[],\\\"author\\\":[]}\",\"id\":\"1392610167\",\"_version_\":1529502580976123905,\"timestamp\":\"2016-03-22T11:48:48.353Z\",\"score\":17.585644}]}}\n
    """
    @all_articles_response """
    {\"responseHeader\":{\"status\":0,\"QTime\":6,\"params\":{\"fl\":\"id,cluster_id_ss, issn_ss, fulltext_list_ssf, access_ss\",\"sort\":\"id asc\",\"q\":\"format:article\",\"cursorMark\":\"*\",\"wt\":\"json\"}},\"response\":{\"numFound\":2708,\"start\":0,\"docs\":[{\"access_ss\":[\"dtupub\",\"dtu\"],\"cluster_id_ss\":[\"2842957\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0908.3349\\\"}\"],\"id\":\"0\"},{\"access_ss\":[\"dtupub\",\"dtu\"],\"cluster_id_ss\":[\"3139121\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0801.1253\\\"}\"],\"id\":\"1\"},{\"access_ss\":[\"dtupub\",\"dtu\"],\"cluster_id_ss\":[\"3444778\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"arxiv\\\",\\\"local\\\":false,\\\"type\\\":\\\"other\\\",\\\"url\\\":\\\"http://arxiv.org/abs/0710.3111\\\"}\"],\"id\":\"10\"},{\"issn_ss\":[\"21511950\",\"21511969\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"scirp\\\",\\\"local\\\":true,\\\"type\\\":\\\"openaccess\\\",\\\"url\\\":\\\"scirp?pi=%2Fjournal%2FPaperDownload.aspx%3FDOI%3D10.4236%2Fjgis.2009.11007&key=193206913\\\"}\"],\"access_ss\":[\"dtupub\",\"dtu\"],\"cluster_id_ss\":[\"84586616\"],\"id\":\"100\"},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569811\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.219\\\"}\"],\"id\":\"1000\"},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569812\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.207\\\"}\"],\"id\":\"1001\"},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569813\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.226\\\"}\"],\"id\":\"1002\"},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569814\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.213\\\"}\"],\"id\":\"1003\"},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569815\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.201\\\"}\"],\"id\":\"1004\"},{\"access_ss\":[\"dtu\"],\"cluster_id_ss\":[\"184569816\"],\"fulltext_list_ssf\":[\"{\\\"source\\\":\\\"hindawi\\\",\\\"local\\\":false,\\\"type\\\":\\\"publisher\\\",\\\"url\\\":\\\"http://dx.doi.org/10.1100/tsw.2010.203\\\"}\"],\"id\":\"1005\"}]},\"nextCursorMark\":\"AoEkMTAwNQ==\",\"facet_counts\":{\"facet_queries\":{},\"facet_fields\":{},\"facet_dates\":{},\"facet_ranges\":{},\"facet_intervals\":{},\"facet_heatmaps\":{}}}\n
    """
    @empty_articles_response """
    {\"responseHeader\":{\"status\":0,\"QTime\":0,\"params\":{\"sort\":\"id asc\",\"q\":\"issn_ss:\\\"16123174\\\"\",\"cursorMark\":\"AoEkMzgzMg==\",\"wt\":\"json\",\"fq\":\"format:\\\"journal\\\"\"}},\"response\":{\"numFound\":1,\"start\":0,\"docs\":[]},\"nextCursorMark\":\"AoEkMTAwNQ==\"}\n
    """
    # Little bit messy, but we use this method
    # to simulate different Solr responses for different queries
    def get(query_string) do
      cond do
        String.contains?(query_string, "AoEkMTAwNQ") -> @empty_articles_response
        String.contains?(query_string, "format%3Aarticle") -> @all_articles_response
        String.contains?(query_string, "issn") -> @journal_response
        true ->
          Logger.error "Unknown query string #{query_string}"
          "{}"
      end
    end

    def simple_get(_,_), do: @all_articles_response

    def journal_response, do: @journal_response
    def all_articles_response, do: @all_articles_response
  end
end
