defmodule AccessDecider do
  require Logger

  @dtu_only ["dtu"]
  @open_access ["dtupub", "dtu"]
  @embargoed ["embargo"]
  @open_access_metastore [fulltext_access: @open_access, fulltext_info: "metastore"]
  @dtu_access_metastore [fulltext_access: @dtu_only, fulltext_info: "metastore"]
  @open_access_sfx [fulltext_access: @open_access, fulltext_info: "sfx"]
  @embargo_sfx [fulltext_access: @embargoed, fulltext_info: "sfx"]
  @dtu_access_sfx [fulltext_access: @dtu_only, fulltext_info: "sfx"]

  def create_update(solr_doc, cache_pid) do
    decide(solr_doc, cache_pid)
    |> Enum.into(%{})
    |> Map.merge(%{id: solr_doc.id})
    |> MetastoreUpdate.new
  end

  @doc """
  Make fulltext availability decision based on
  1) fulltext information in Solr document
  2) Journal information in SFX (stored in Metastore)
  Returns list containing the access permitted and the source
  for this information, either sfx or metastore, e.g.
  [fulltext_access: ["dtu"], fulltext_info: "sfx"]
  """
  def decide(solr_doc, cache_pid) do
    check_fulltext_availability(solr_doc, cache_pid, [
        &is_ebook/2,
        &open_access_thesis?/2,
        &metastore_fulltext/2,
        &open_access_journal?/2,
        &sfx_journal?/2,
        &sfx_fulltext/2,
    ])
  end

  # If none of the checks return results
  defp check_fulltext_availability(_doc, _pid, []), do: [fulltext_access: [], fulltext_info: "none"]

  # run through all check functions returning the value of the first successful check
  defp check_fulltext_availability(doc, cache_pid, [check_function | remaining_functions]) do
    case check_function.(doc, cache_pid) do
      nil -> check_fulltext_availability(doc, cache_pid, remaining_functions)
      x when is_list(x) -> x
    end
  end

  def is_ebook(solr_doc, _cache_pid) do
    if solr_doc.format == "book" && "dtu_sfx" in solr_doc.source_ss do
      [fulltext_access: @dtu_only, fulltext_info: "sfx"]
    end
  end

  def open_access_thesis?(solr_doc, _cache_pid) do
    if solr_doc.format == "thesis" && SolrDoc.pure_source?(solr_doc) && SolrDoc.fulltext_url?(solr_doc) do
      @open_access_metastore
    end
  end

  @doc """
  If the doc comes from SFX there is access for DTU users. If the doc has 'open access' in its title.
  there is access for all users.
  """
  def sfx_journal?(%SolrDoc{format: "journal", source_ss: sources, journal_title_ts: titles}, _cache_pid) do
    if "jnl_sfx" in sources do
      if Enum.any?(titles, fn(t) -> String.downcase(t) |> String.contains?("open access") end) do
        @open_access_sfx
      else
        @dtu_access_sfx
      end
    end
  end

  def sfx_journal?(%SolrDoc{}, _cache_pid), do: nil

  def open_access_journal?(%SolrDoc{format: "journal", journal_title_ts: titles}, _cache_pid) do
    if Enum.any?(titles, fn(t) -> String.downcase(t) |> String.contains?("open access") end) do
      @open_access_metastore
    end
  end

  def open_access_journal?(%SolrDoc{}, _cache_pid), do: nil

  @doc """
  Check for fulltext based on the SFX journal information
  (held in Metastore)
  """
  def sfx_fulltext(doc, cache_pid) do
    journal = JournalCache.journal_for_article(cache_pid, doc)
    sfx_fulltext(doc, cache_pid, journal)
  end

  def sfx_fulltext(doc, _cache_pid, journal) do
    cond do
      is_nil(journal) -> nil
      %SolrJournal{} == journal -> nil
      SolrJournal.holdings(journal) == "NONE" -> nil
      SolrJournal.under_embargo?(journal: journal, article: doc) ->
        @embargo_sfx
      SolrJournal.open_access?(journal) ->
        @open_access_sfx
      SolrJournal.within_holdings?(journal: journal, article: doc) ->
        @dtu_access_sfx
      true -> nil
    end
  end

  @doc """
  Check if there is fulltext access based on
  the information in the Solr document.
  """
  def metastore_fulltext(solr_doc, _cache_pid) do
    fulltext_types = SolrDoc.fulltext_types(solr_doc)
    cond do
      is_nil(fulltext_types) -> nil
      Enum.member?(fulltext_types, "openaccess") ->  
        @open_access_metastore
      Enum.member?(fulltext_types, "research") -> 
        @open_access_metastore
      Enum.member?(fulltext_types, "publisher") -> 
        @dtu_access_metastore
      true ->
        Logger.debug "Unknown fulltext type [#{Enum.join(fulltext_types, ", ")}] - doing nothing"
        nil
    end
  end
end
