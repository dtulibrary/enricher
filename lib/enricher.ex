defmodule Enricher do
  use Application
  require Logger
  # If there is no schedule configured, we'll use a yearly schedule to prevent it running
  # in our tests and development. i.e. this value should only be _real_ in production. 
  @full_run_schedule Application.get_env(:enricher, :full_run_schedule, "@yearly")
  @update_schedule Application.get_env(:enricher, :update_schedule, "@yearly")
  @min 60000
  @max 100000
  alias Experimental.GenStage
  use GenStage
  require Logger

  def start(_type, _args) do
    Logger.info "Initialising Enricher"
    full_run = %Quantum.Job{schedule: @full_run_schedule, task: fn -> start_harvest(:full) end}
    partial_run = %Quantum.Job{schedule: @update_schedule, task: fn -> start_harvest(:partial) end}
    Logger.info "Scheduling harvest jobs"
    Quantum.add_job(:full, full_run)
    Quantum.add_job(:partial, partial_run)
    {:ok, self}
  end

  def start_harvest(mode) do
    Logger.info "Starting #{mode} harvest..."
    {:ok, commit_manager} = CommitManager.start_link
    {:ok, harvest} = GenStage.start_link(HarvestStage, mode)
    {:ok, cache_pid} = GenServer.start_link(JournalCache, [])
    JournalCache.load_journals(cache_pid)
    {:ok, decider1} = GenStage.start_link(DeciderStage, cache_pid)
    {:ok, decider2} = GenStage.start_link(DeciderStage, cache_pid)
    {:ok, decider3} = GenStage.start_link(DeciderStage, cache_pid)
    {:ok, decider4} = GenStage.start_link(DeciderStage, cache_pid)
    {:ok, update1} = GenStage.start_link(UpdateStage, commit_manager)
    {:ok, update2} = GenStage.start_link(UpdateStage, commit_manager)
    {:ok, update3} = GenStage.start_link(UpdateStage, commit_manager)
    {:ok, update4} = GenStage.start_link(UpdateStage, commit_manager)
    GenStage.sync_subscribe(update1, to: decider1, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(update2, to: decider2, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(update3, to: decider3, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(update4, to: decider4, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(decider1, to: harvest, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(decider2, to: harvest, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(decider3, to: harvest, min_demand: @min, max_demand: @max)
    GenStage.sync_subscribe(decider4, to: harvest, min_demand: @min, max_demand: @max)
  end
end
