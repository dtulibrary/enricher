defmodule JournalFetcherTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = GenServer.start_link(JournalFetcher, :journals)
    {:ok, fetcher: pid}
  end
  test "fetch_journal", %{fetcher: fetcher} do
    # when it is not present in :ets it should be stored after retrieval  
    assert is_map(JournalFetcher.fetch(fetcher, {:issn, "5678"}))
    {_key, j} = :ets.lookup(:journals, "issn:5678") |> hd
    assert is_map(j)
  end
  test "using :ets", %{fetcher: fetcher} do
    doc = SolrJournal.new(title_ts: "value")
    JournalFetcher.insert(fetcher, {:issn, "1234", doc})
    assert doc == JournalFetcher.fetch(fetcher, {:issn, "1234"})
  end

end
