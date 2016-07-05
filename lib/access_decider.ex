defmodule AccessDecider do
  require Logger

  @dtu_only ["dtu"]
  @open_access ["dtupub", "dtu"]

  @doc """
  Take docs from `doc_stack`, determine their
  online access status and add this data to the
  `update_stack`
  """
  def process(doc_stack, update_stack) do
    case Stack.pop(doc_stack) do
      nil ->
        Logger.debug "AccessDecider: No more docs on stack, exiting..."
        {:ok}
      %SolrDoc{} = doc ->
        Logger.debug "AccessDecider processing..."
        access = decide(doc)
        Stack.push(update_stack, {doc.id, access})
        process(doc_stack, update_stack)
    end
  end

  @doc """
  Make fulltext availability decision based on
  1) fulltext information in Solr document
  2) Journal information in SFX (stored in Metastore)
  """
  def decide(solr_doc) do
    check_fulltext_availability(solr_doc, [
        &is_book/1,
        &metastore_fulltext/1,
        &sfx_fulltext/1,
    ])
  end

  defp check_fulltext_availability(doc, []), do: []

  # run through all check functions returning the value of the first successful check
  defp check_fulltext_availability(doc, [check_function | remaining_functions]) do
    case check_function.(doc) do
      nil -> check_fulltext_availability(doc, remaining_functions)
      x when is_list(x) -> x
    end
  end

  def is_book(solr_doc) do
    if solr_doc.format == "book", do: @dtu_only
  end

  @doc """
  Check for fulltext based on the SFX journal information
  (held in Metastore)
  """
  def sfx_fulltext(doc) do
    journal = SolrClient.journal_for_article(doc)
    cond do
      is_nil(journal) -> []
      SolrJournal.open_access?(journal) -> @open_access
      SolrJournal.within_holdings?(journal: journal, article: doc) -> @dtu_only
      true -> []
    end
  end

  @doc """
  Check if there is fulltext access based on
  the information in the Solr document.
  """
  def metastore_fulltext(solr_doc) do
    fulltext_types = SolrDoc.fulltext_types(solr_doc)
    cond do
      is_nil(fulltext_types) -> nil
      Enum.member?(fulltext_types, "openaccess") ->  @open_access
      Enum.member?(fulltext_types, "research") -> @open_access
      Enum.member?(fulltext_types, "publisher") -> @dtu_only
      true ->
        Logger.error "AccessDecider: Unknown fulltext type [#{Enum.join(fulltext_types, ", ")}] - doing nothing"
        nil
    end
  end
end