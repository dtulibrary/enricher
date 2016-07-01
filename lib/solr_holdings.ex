defmodule SolrHoldings do
  @moduledoc """
  Query interface for journal holdings information
  stored in Solr
  """

  @doc """
  Returns the coverage for a journal given a specific identifier

  ```
  SolrHoldings.get_coverage("issn", "0036-1399")
  => [from: {1966, 14, 1}, to: {}, embargo: 0]
  ```
  """
  def get_coverage(identifier, value) do
    SolrClient.fetch_journal(identifier, value)
    |> SolrJournal.holdings
  end
end
