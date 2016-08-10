defmodule Enricher do
  use Application
  require Logger
  # If there is no schedule configured, we'll use a yearly schedule to prevent it running
  # in our tests and development. i.e. this value should only be _real_ in production. 
  @full_run_schedule Application.get_env(:enricher, :full_run_schedule, "@yearly")
  @update_schedule Application.get_env(:enricher, :update_schedule, "@yearly")

  alias Experimental.GenStage
  use GenStage
  require Logger

  def start(_type, _args) do
    Logger.info "Initialising Enricher"
    full_run = %Quantum.Job{schedule: @full_run_schedule, task: fn -> start_harvest(:full) end}
    partial_run = %Quantum.Job{schedule: @update_schedule, task: fn -> start_harvest(:partial) end}
    Logger.info "Scheduling harvest jobs"
    Quantum.add_job(:full, full_run)
    Quantum.add_job(:partial, full_run)
    {:ok, self}
  end

  def start_harvest(mode) do
    Logger.info "Starting #{mode} harvest..."
    {:ok, decider} = GenStage.start_link(DeciderStage, :ok)
    {:ok, harvest} = GenStage.start_link(HarvestStage, mode)
    {:ok, update} = GenStage.start_link(UpdateStage, :ok)
    GenStage.sync_subscribe(update, to: decider)
    GenStage.sync_subscribe(decider, to: harvest)
  end
end
