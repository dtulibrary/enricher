defmodule Enricher do
  use Application
  require Logger
  alias Experimental.GenStage
  use GenStage

  @min 60000
  @max 100000

  def start(_type, _args) do
    import Supervisor.Spec
    Logger.info "Initialising Enricher"
    JournalCache.create_ets
    children = [
      worker(Enricher.HarvestManager, [Manager]),
      worker(JournalCache, [Cache]),
      worker(Enricher.LogServer, [WebLogger]),
      Plug.Adapters.Cowboy.child_spec(:http, Enricher.Web, [], [port: 4001])
    ]
    {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)
  end

  def start_harvest(mode) do
    Enricher.LogServer.flush_log(WebLogger)
    JournalCache.load_journals(Cache)
    {:ok, harvest} = GenStage.start_link(HarvestStage, mode)
    {:ok, decider1} = GenStage.start_link(DeciderStage, Cache)
    {:ok, decider2} = GenStage.start_link(DeciderStage, Cache)
    {:ok, decider3} = GenStage.start_link(DeciderStage, Cache)
    {:ok, decider4} = GenStage.start_link(DeciderStage, Cache)
    {:ok, update1} = GenStage.start_link(UpdateStage, [])
    {:ok, update2} = GenStage.start_link(UpdateStage, [])
    {:ok, update3} = GenStage.start_link(UpdateStage, [])
    {:ok, update4} = GenStage.start_link(UpdateStage, [])
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
