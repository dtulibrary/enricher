defmodule Helpers do
  @doc """
  Given an article's cluster id 
  Show how Enricher will decide its access.
  """
  def test_article(id) do
    IO.puts "Determining access for #{id}..."
    {:ok, cache_pid} = GenServer.start_link(JournalCache, [])
    JournalCache.load_journals(cache_pid)
    SolrClient.fetch_article(id)
    |> AccessDecider.decide(cache_pid) 
    |> IO.inspect
  end

  @doc """
  Given an article's cluster id 
  update the relevant document in Solr.
  """
  def update_article(id) do
    {:ok, cache_pid} = GenServer.start_link(JournalCache, [])
    JournalCache.load_journals(cache_pid)
    update = SolrClient.fetch_article(id) |> AccessDecider.create_update(cache_pid)
    [update] |> MetastoreUpdater.update_docs
    MetastoreUpdater.commit_updates
    IO.inspect update
    update
  end
end
