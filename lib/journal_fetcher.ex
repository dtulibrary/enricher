defmodule JournalFetcher do
  require Logger
  
  @doc """
  Fetch journals from ETS if they are present
  otherwise, fetch from Solr and persist to ETS
  for next time
  """
  def fetch(pid, {key, value}) do
    GenServer.call(pid, {:fetch, key, value}, 20000)
  end

  def insert(pid, {key, value, doc}) do
    GenServer.cast(pid, {:insert, key, value, doc})
  end 

  # Server API

  def init(name) do
    :ets.new(name, [:named_table])
    {:ok, name}
  end

  def handle_call({:fetch, key, value},_from, name) do
    case fetch_ets(name, key, value) do
      nil -> 
        doc = fetch_from_solr(name, key, value)
        {:reply, doc, name}
      journal -> {:reply, journal, name}
    end
  end

  def handle_cast({:insert, key, value, doc}, name) do
    :ets.insert(name, {"#{key}:#{value}", doc})
    {:noreply, name}
  end

  defp fetch_ets(name, key, value) do
    case :ets.lookup(name, "#{key}:#{value}") do
      [{_id, doc}|_] -> doc
      [] -> nil
    end
  end

  defp fetch_from_solr(name, key, value) do
    Logger.debug "fetching from solr"
    doc = SolrClient.fetch_journal(key, value)
    unless is_nil(doc) do 
      :ets.insert(name, {"#{key}:#{value}", doc})
    end
    doc
  end

  def terminate(reason, name) do
    Logger.error "terminating... #{inspect reason}"
    Logger.error "Closing down ets #{name}"
    :ets.delete(name)
  end
end
