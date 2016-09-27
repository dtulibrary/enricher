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
end
