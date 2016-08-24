defmodule JournalFetcherTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = GenServer.start_link(JournalFetcher, :journals)
    {:ok, fetcher: pid}
  end
  describe "fetch\2" do
    test "non-cached journals should be stored after retrieval", %{fetcher: fetcher} do
      assert is_map(JournalFetcher.fetch(fetcher, {:issn, "5678"}))
      {_key, j} = :ets.lookup(:journals, "issn:5678") |> hd
      assert is_map(j)
    end
    test "cached journals should be used instead of http queries", %{fetcher: fetcher} do
      doc = SolrJournal.new(title_ts: "value")
      JournalFetcher.insert(fetcher, {:issn, "1234", doc})
      assert doc == JournalFetcher.fetch(fetcher, {:issn, "1234"})
    end
  end
  test "empty responses should also be cached", %{fetcher: fetcher} do
    JournalFetcher.insert(fetcher, {:issn, "9876", nil})
    result = JournalFetcher.fetch(fetcher, {:issn, "9876"})
    assert is_nil(result)
  end
end
