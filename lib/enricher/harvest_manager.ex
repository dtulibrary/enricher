defmodule Enricher.HarvestManager do
  @moduledoc """
  This server's role is to maintain stateful
  information about the current harvest which can
  be accessed by the various components as well
  as by the web interface
  """
  use GenServer
  require Logger

  ## Client API ##

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, Enricher.Status.new(%{}), [name: name])
  end

  def status(pid) do
    GenServer.call(pid, :status)
  end

  def search_endpoint(pid) do
    endpoint(pid) <> "/solr/metastore/toshokan"
  end

  def update_endpoint(pid) do
    endpoint(pid) <> "/solr/metastore/update"
  end

  def endpoint(pid) do
    status(pid) |> Map.get(:endpoint)
  end
  
  def update_count(pid, increment) do
    GenServer.call(pid, {:update_count, increment})
  end

  def start_harvest(pid, mode, endpoint) do
    GenServer.call(pid, {:start_harvest, mode, endpoint})
  end
  
  def harvest_complete(pid) do
    GenServer.call(pid, :harvest_complete)
  end

  ## Server API ##

  def init(_,_), do: {:ok, Enricher.Status.new(%{})}

  def handle_call(:status, _from, status), do: {:reply, status, status}

  def handle_call({:update_count, increment}, _from, status) do
    new_count = Map.get(status, :docs_processed) + increment
    updated_status = status |> Map.merge(%{docs_processed: new_count})
    {:reply, :ok, updated_status}
  end
  
  def handle_call({:start_harvest, mode, endpoint}, _from, status) do
    Logger.info "Starting #{mode} harvest..."
    updated_status = status |> Map.merge(%{start_time: DateTime.utc_now, in_progress: true, endpoint: endpoint, mode: mode})
    Task.async(fn -> Enricher.start_harvest(mode) end)
    {:reply, :ok, updated_status}
  end

  def handle_call(:harvest_complete, _from, status) do
    updated_status = status |> Map.merge(%{in_progress: false, end_time: DateTime.utc_now})
    {:reply, :ok, updated_status}
  end
end
