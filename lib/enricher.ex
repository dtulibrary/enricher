defmodule Enricher do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec
    JournalCache.create_ets
    children = [
      worker(Enricher.HarvestManager, [Manager]),
      worker(JournalCache, [Cache]),
      worker(Enricher.LogServer, [WebLogger]),
      worker(Enricher.StageManager, [StageManager]),
      Plug.Adapters.Cowboy.child_spec(:http, Enricher.Web, [], [port: 4001])
    ]
    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)
    Logger.info "Enricher initialised..."
    {:ok, pid} 
  end
end

