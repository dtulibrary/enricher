defmodule CommitManager do
  @moduledoc """
  Keeps track of the number of updates that have been
  made to Solr and triggers commits when the buffer is full.
  """
  use GenServer
  require Logger

  ## Client API ##

  @buffer_size 5000000
  @updater Application.get_env(:enricher, :metastore_updater, MetastoreUpdater)

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, 0, [name: name]) 
  end

  def update(pid, number) do
    GenServer.call(pid, {:update, number})
  end

  def current_count(pid) do
    GenServer.call(pid, {:current_count})
  end

  def buffer_size, do: @buffer_size

  ## Server API ##

  def handle_call({:update, number}, _from, update_count) when (number + update_count) >= @buffer_size do
    Logger.info "Update buffer exceeded - committing updates..."
    @updater.commit_updates
    {:reply, :ok, 0}
  end

  def handle_call({:update, number}, _from, update_count) when (number + update_count) < @buffer_size do
    Logger.debug "Increasing buffer size to #{number + update_count}"
    {:reply, :ok, number + update_count}
  end

  def handle_call({:current_count}, _from, update_count) do
    {:reply, update_count, update_count}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 200}, update_count) do
    Logger.info "Commit succeeded"
    {:noreply, [], update_count}
  end

  # We also get some Async headers and stuff that we're not really interested in
  def handle_info(_generic, state), do: {:noreply, [], state}

  defmodule TestUpdater do
    @moduledoc """
    This module exists purely to allow the 
    commit manager to be testable without 
    a running Solr.
    """
    def commit_updates, do: :ok
  end
end
