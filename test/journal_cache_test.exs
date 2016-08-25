defmodule JournalCacheTest do
  use ExUnit.Case

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
end
