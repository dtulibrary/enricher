defmodule CommitManager do
  @moduledoc """
  Keeps track of the number of updates that have been
  made to Solr and triggers commits when the buffer is full.
  """
  use GenServer
  require Logger

  defmodule State do
    defstruct [number: 0, updaters: []]
    use ExConstructor
  end
  
  ## Client API ##

  @buffer_size 5000000
  @updater Application.get_env(:enricher, :metastore_updater, MetastoreUpdater)

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, [], [name: name]) 
  end

  def update(pid, number) do
    GenServer.call(pid, {:update, number})
  end

  def current_count(pid) do
    GenServer.call(pid, {:current_count})
  end

  def register_updater(pid, updater_pid) do
    GenServer.call(pid, {:register_updater, updater_pid})
  end

  def deregister_updater(pid, updater_pid) do
    GenServer.call(pid, {:deregister_updater, updater_pid})
  end

  def updaters(pid) do
    pid |> state |> Map.get(:updaters)
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def buffer_size, do: @buffer_size

  ## Server API ##

  def init([]) do
    {:ok, State.new(%{})}
  end

  def handle_call({:update, number}, _from, state) do
    new_state = 
      cond do
        number + state.number >= @buffer_size ->
          Logger.info "Update buffer exceeded - committing updates..."
          @updater.commit_updates
          Map.merge(state, %{number: 0})
        :else ->
          Map.merge(state, %{number: state.number + number})
        end
    {:reply, :ok, new_state}
  end

  def handle_call({:current_count}, _from, state) do
    {:reply, state.number, state}
  end

  def handle_call({:register_updater, updater}, _from, state) do
    new_state = Map.merge(state, %{updaters: state.updaters ++ [updater]})
    {:reply, :ok, new_state}
  end

  def handle_call({:deregister_updater, updater}, _from, state) do
    new_updaters = Enum.reject(state.updaters, fn(pid) -> pid == updater end)
    new_state = Map.merge(state, %{updaters: new_updaters})
    if (length(new_updaters) == 0 && length(state.updaters) > 0) do
      Logger.warn "All updaters have ceased - committing updates"
      new_state = Map.merge(new_state, %{number: 0})
      @updater.commit_updates(new_searcher: true)
    end
    {:reply, :ok, new_state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  defmodule TestUpdater do
    @moduledoc """
    This module exists purely to allow the 
    commit manager to be testable without 
    a running Solr.
    """
    def commit_updates, do: :ok
  end
end
