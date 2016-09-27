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

  def load_journals(pid, endpoint) do
    Logger.info "Loading journals"
    journals = SolrClient.all_journals(endpoint)
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

  def last_updated(pid) do
    GenServer.call(pid, :last_updated)
  end

  @doc """
  Given a document representing an article
  retrieve the article's journal from the cache
  if it's present.
  Else, retrieve an empty %SolrJournal{}
  """
  def journal_for_article(pid, article) do
    identifiers = SolrDoc.all_identifiers(article) |> Enum.map(fn {x,y} -> "#{x}:#{y}" end)
    JournalCache.fetch_journal(pid, identifiers)
  end

  ## Server API ##

  def init(_args) do
    cache = create_ets
    {:ok, {cache, nil}}
  end

  @doc """
  Allow the ets to be created as part of the startup 
  or externally by a parent process.
  Creating it externally means that it will not be garbage
  collected if the cache process dies, thus meaning it will
  persist across restarts.
  """
  def create_ets(name \\ :journals) do
    try do
      :ets.new(name, [:ordered_set, :named_table, :public])
    rescue
      ArgumentError -> 
        Logger.info "ETS already exists!"
        name
    end
  end

  def handle_call({:load, journals}, _from, {cache, timestamp}) do
    journals |> Enum.each(&insert(cache, &1))
    {:reply, :ok, {cache, DateTime.utc_now}}
  end

  def handle_call({:insert, journal}, _from, {cache, timestamp}) do
    insert(cache, journal)
    {:reply, :ok, {cache, timestamp}}
  end

  def handle_call({:fetch, identifiers}, _from, {cache, timestamp}) when is_list(identifiers) do
    journal = case fetch_all(identifiers, cache) do
      [] -> %SolrJournal{}
      [h|_] -> h
    end
    {:reply, journal, {cache, timestamp}}
  end

  def handle_call({:fetch, identifier}, _from, {cache, timestamp}) do
    journal = case fetch_from_ets(cache, identifier) do
      nil -> %SolrJournal{}
      journal -> journal
    end
    {:reply, journal, {cache, timestamp}}
  end

  defp fetch_all(identifiers, cache) do
    identifiers |> Enum.map(&fetch_from_ets(cache, &1)) |> Enum.reject(&is_nil(&1)) 
  end

  defp fetch_from_ets(cache, identifier) do
    case :ets.lookup(cache, identifier) do
      [{_id, j}|_] -> j
      [] -> nil
    end
  end

  def handle_call(:last_updated, _from, {cache, timestamp}) do
    {:reply, timestamp, {cache, timestamp}}
  end

  defp insert(cache, journal) do
    SolrJournal.identifiers(journal)
    |> Enum.each(fn(id) ->
      :ets.insert(cache, {id, journal})
    end)
  end
end
