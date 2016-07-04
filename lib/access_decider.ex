defmodule AccessDecider do
  @dtu_only ["dtu"]
  @open_access ["dtupub", "dtu"]

  def run(stack) do
    # 1. get doc from stack
    solr_doc = Stack.pop(stack)
    # 2. get holdings info for doc
    # 3. make access decision
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
      SolrJournal.open_access?(journal) -> @open_access
      SolrJournal.within_holdings?(journal: journal, article: doc) -> @dtu_only
      :else -> []
    end
  end

  @doc """
  Check if there is fulltext access based on
  the information in the Solr document.
  """
  def metastore_fulltext(solr_doc) do
    access_types = SolrDoc.fulltext_types(solr_doc)
    cond do
      is_nil(access_types) -> nil
      Enum.member?(access_types, "openaccess") ->  @open_access
      Enum.member?(access_types, "research") -> @open_access
      Enum.member?(access_types, "publisher") -> @dtu_only
    end
  end
end
