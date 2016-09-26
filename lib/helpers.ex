defmodule Helpers do
  @doc """
  Given an article's cluster id 
  Show how Enricher will decide its access.
  """
  def test_article(id, endpoint) do
    article = SolrClient.fetch_article(id, endpoint)
    journal = JournalCache.journal_for_article(Cache, article)
    decision = AccessDecider.decide(article, Cache) 
    {article, journal, decision}
  end

  @doc """
  Given an article's cluster id 
  update the relevant document in Solr.
  """
  def update_article(id) do
    JournalCache.create_ets
    update = SolrClient.fetch_article(id) |> AccessDecider.create_update(Cache)
    [update] |> MetastoreUpdater.update_docs
    MetastoreUpdater.commit_updates
    IO.inspect update
    update
  end
end
