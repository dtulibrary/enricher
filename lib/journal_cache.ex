defmodule JournalCache do
  @moduledoc """
  This module is responsible for getting
  and caching all SFX journal documents 
  from Metastore.  
  """
  require Logger

  ## Client API ##

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, [], [name: name])
  end

  @doc """
  Load all SFX journals from Metastore
  """
  def load_journals(pid) do
    Logger.info "Loading journals"
    journals = SolrClient.all_journals
    GenServer.call(pid, {:load, journals}, 120000)
  end

  @doc """
  Fetch journals from ETS if they are present
  Otherwise, return an empty %SolrJournal{}
  """
  def fetch_journal(pid, identifier) do
    GenServer.call(pid, {:fetch, identifier})
  end

  @doc """
  Add the given journal to ETS, with
  one entry for each identifier
  """
  def insert_journal(pid, journal) do
    GenServer.call(pid, {:insert, journal})
  end

  @doc """
  Given a document representing an article
  retrieve the article's journal from the cache
  if it's present.
  Else, retrieve an empty %SolrJournal{}
  """
  def journal_for_article(pid, article) do
    {identifier, value} = SolrDoc.identifier(article)
    JournalCache.fetch_journal(pid, "#{identifier}:#{value}")
  end

  ## Server API ##

  def init(_args) do
    cache = :ets.new(:journals, [:ordered_set])
    {:ok, cache}
  end

  def handle_call({:load, journals}, _from, cache) do
    journals |> Enum.each(&insert(cache, &1))
    {:reply, :ok, cache}
  end

  def handle_call({:insert, journal}, _from, cache) do
    insert(cache, journal)
    {:reply, :ok, cache}
  end

  def handle_call({:fetch, identifier}, _from, cache) do
    journal = case :ets.lookup(cache, identifier) do
      [{_id, j}|_] -> j
      [] -> %SolrJournal{}
    end
    {:reply, journal, cache}
  end

  defp insert(cache, journal) do
    SolrJournal.identifiers(journal)
    |> Enum.each(fn(id) ->
      :ets.insert(cache, {id, journal})
    end)
  end
end
