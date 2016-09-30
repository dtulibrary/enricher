defmodule Enricher.HarvestManager do
  @moduledoc """
  This server's role is to maintain stateful
  information about the current harvest which can
  be accessed by the various components as well
  as by the web interface
  """
  use GenServer
  require Logger
  # Allows injection of a dummy module for unit tests
  @harvest_module Application.get_env(:enricher, :harvest_module, Enricher)

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

  def update_batch_size(pid, batch_size) do
    new_status = status(pid) |> Map.merge(%{batch_size: batch_size})
    update_status(pid, new_status)
  end

  def update_status(pid, new_status) do
    GenServer.call(pid, {:update_status, new_status})
  end

  def start_harvest(pid, mode, endpoint) do
    GenServer.call(pid, {:start_harvest, mode, endpoint})
  end

  def stop_harvest(pid) do
    GenServer.call(pid, :stop_harvest)
  end
  
  def harvest_complete(pid) do
    GenServer.call(pid, :harvest_complete)
  end

  ## Server API ##

  def init(_,_), do: {:ok, Enricher.Status.new(%{})}

  def handle_call(:status, _from, status), do: {:reply, status, status}

  def handle_call(:stop_harvest, _from, status) do
    Logger.warn "Stopping harvest..."
    if Process.alive?(status.reference.pid) do
      Task.shutdown(status.reference)
    end
    MetastoreUpdater.commit_updates(url: "#{status.endpoint}", new_searcher: true)
    updated_status = status |> Map.merge(%{in_progress: false})
    {:reply, :ok, updated_status}
  end

  def handle_call({:update_status, new_status}, _from, status) do
    updated_status = status |> Map.merge(new_status)
    {:reply, :ok, updated_status}
  end

  def handle_call({:update_count, increment}, _from, status) do
    new_count = Map.get(status, :docs_processed) + increment
    updated_status = status |> Map.merge(%{docs_processed: new_count})
    {:reply, :ok, updated_status}
  end
  
  def handle_call({:start_harvest, mode, endpoint}, _from, status) do
    case Map.get(status, :in_progress) do
      true ->
        Logger.error "Cannot start harvest - harvest already in progress"
        {:reply, :error, status}
      false ->
        Logger.info "Starting #{mode} harvest..."
        ref = Task.async(fn -> @harvest_module.start_harvest(mode) end)
        status = Enricher.Status.new(%{
          start_time: DateTime.utc_now,
          in_progress: true,
          endpoint: endpoint, 
          mode: mode,
          reference: ref
        })
        {:reply, :ok, status}
    end
  end

  def handle_call(:harvest_complete, _from, status) do
    updated_status = status |> Map.merge(%{in_progress: false, end_time: DateTime.utc_now})
    {:reply, :ok, updated_status}
  end

  @doc """
  Handle stop message from Harvest Task.
  If reference matches current Harvest job,
  update the status.
  """
  def handle_info({:DOWN, ref, :process, _pid, reason}, status) do
    Logger.debug "Received DOWN message for process #{inspect ref} with reason #{reason}"
    updated_status = 
      cond do
        ref == status.reference ->
          Map.merge(status, %{in_progress: false})
        :else -> status 
      end
    {:noreply, updated_status}
  end

  def handle_info(_msg, state), do: {:noreply, state}

end
