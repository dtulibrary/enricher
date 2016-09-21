defmodule JournalCacheTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, pid} = GenServer.start_link(JournalCache, [])
    journal = %SolrJournal{issn_ss: ["12345678"], eissn_ss: ["98765432"]}
    {:ok, pid: pid, journal: journal}
  end
  describe "insert_journal" do
    test "inserting a journal with multiple identifiers", %{pid: pid, journal: journal} do
      JournalCache.insert_journal(pid, journal)
      assert JournalCache.fetch_journal(pid, "issn_ss:12345678") == journal
      assert JournalCache.fetch_journal(pid, "eissn_ss:98765432") == journal
    end
  end
  describe "fetch_journal\2" do
    test "retrieving a journal that is not present should return an empty journal", %{pid: pid} do
      assert %SolrJournal{} == JournalCache.fetch_journal(pid, "issn_ss:nothere")  
    end
  end

  describe "journal_for_article\2" do
    test "when the journal is cached", %{pid: pid, journal: journal} do
      JournalCache.insert_journal(pid, journal)
      article = %SolrDoc{issn_ss: ["12345678"]}
      assert journal == JournalCache.journal_for_article(pid, article)
    end
    test "when the journal is not cached", %{pid: pid} do
      assert %SolrJournal{} == JournalCache.journal_for_article(pid, %SolrDoc{issn_ss: ["5438763"]})
    end
  end
  describe "when setup as part of a supervision tree" do
    setup [:start_with_supervisor]
    test "it can be found", %{cache_pid: cache_pid} do
      assert Process.alive?(cache_pid)
    end
    test "it is restarted automatically", %{cache_pid: cache_pid} do
      Process.exit(cache_pid, :error)
      ref = Process.monitor(cache_pid)
      assert_receive {:DOWN, ^ref, _,_,_}
      :timer.sleep(1)
      new_cache_pid = Process.whereis(TestCache)
      refute new_cache_pid == nil
      assert Process.alive?(new_cache_pid)
    end
    test "it's state persists between restarts", %{cache_pid: cache_pid, journal: journal} do
      JournalCache.insert_journal(TestCache, journal)
      assert JournalCache.fetch_journal(TestCache, "issn_ss:12345678") == journal
      Process.exit(cache_pid, :error)
      ref = Process.monitor(cache_pid)
      assert_receive {:DOWN, ^ref, _,_,_}
      :timer.sleep(1)
      new_cache_pid = Process.whereis(TestCache)
      refute new_cache_pid == nil
      assert JournalCache.fetch_journal(TestCache, "issn_ss:12345678") == journal
    end
  end
  defp start_with_supervisor(context) do
    import Supervisor.Spec
    JournalCache.create_ets
    children = [
      worker(JournalCache, [TestCache])
    ]
    {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)
    cache_pid = Process.whereis(TestCache)
    Map.merge(context, %{cache_pid: cache_pid})
  end
end
