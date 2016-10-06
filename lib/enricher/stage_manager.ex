defmodule Enricher.StageManager do
  @moduledoc """
  This GenServer is responsible for starting
  and stopping harvests and for keeping track of
  the various stage processes to enable 
  orderly shutdown
  """
  alias Experimental.GenStage
  use GenStage
  use GenServer
  require Logger

  @min 60000
  @max 100000

  ##############
  # Client API #
  ##############

  def start_link(name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, [], [name: name])
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  def start_harvest(pid, mode) do
    GenServer.cast(pid, {:start_harvest, mode})
  end
  
  def stop_harvest(pid \\ StageManager) do
    GenServer.cast(pid, :stop_harvest)
  end

  ##############
  # Server API #
  ##############

  defmodule State do
    defstruct [harvesters: [], deciders: [], updaters: []]
    use ExConstructor
  end

  def init(_), do: {:ok, State.new(%{}) }

  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_cast({:start_harvest, mode}, state) do
    Enricher.LogServer.flush_log(WebLogger)
    JournalCache.load_journals(Cache)
    {:ok, harvest} = GenStage.start_link(HarvestStage, mode)
    {:ok, decider1} = GenStage.start_link(DeciderStage, Cache)
    {:ok, decider2} = GenStage.start_link(DeciderStage, Cache)
    {:ok, decider3} = GenStage.start_link(DeciderStage, Cache)
    {:ok, updater1} = GenStage.start_link(UpdateStage, [])
    {:ok, updater2} = GenStage.start_link(UpdateStage, [])
    {:ok, updater3} = GenStage.start_link(UpdateStage, [])
    new_state = State.new(%{
      harvesters: [harvest],
      deciders: [decider1, decider2, decider3],
      updaters: [updater1, updater2, updater3]
    })
    GenStage.sync_subscribe(updater1, to: decider1, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(updater2, to: decider2, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(updater3, to: decider3, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(decider1, to: harvest, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(decider2, to: harvest, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(decider3, to: harvest, min_demand: @min, max_demand: @max)
    {:noreply, new_state}
  end

  def handle_cast(:stop_harvest, state) do
    Logger.info "exit signal received, stopping all stages" 
    quit_processes(state.harvesters)
    quit_processes(state.deciders)
    quit_processes(state.updaters)
    commit_updates
    {:noreply, State.new(%{})}
  end

  def handle_info(:nomoredocs, state) do
    Logger.info "harvest complete, committing updates"
    commit_updates
    {:noreply, State.new(%{})}
  end

  def handle_info(_msg, status), do: {:noreply, status}

  def commit_updates do
    MetastoreUpdater.commit_updates(
      url: Enricher.HarvestManager.update_endpoint(Manager),
      new_searcher: true
    )
  end

  def quit_processes(processes) do
    Enum.each(processes, fn(p) ->
      if Process.alive?(p), do: attempt_stop(p)
    end)
  end

  # This is messy but for some
  # reason exiting the GenStage
  # causes an error on some stages
  defp attempt_stop(pid) do
    try do
      GenStage.stop(pid)
    catch
      :exit, _ -> Logger.error "Could not stop #{inspect pid}"
    end
  end
end
