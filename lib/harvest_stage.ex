alias Experimental.GenStage

defmodule HarvestStage do
  @moduledoc """
  Experimental - attempt to solve our reliability
  problems by re-architecting Enricher as a GenStage app.
  This module should utilise SolrClient to produce events (docs)
  for the DeciderStage
  It's only state should consist of the result set cursor and the harvest mode.
  """

  require Logger
  use GenStage
  @init_cursor "*"
  @doc "mode can be :full or :partial"
  def init(mode) do
    Logger.info "Commencing full harvest"
    {:producer, {mode, @init_cursor}}
  end

  def handle_demand(demand, {:full, cursor}) when demand > 0 do
    Logger.info "Receiving demand #{demand} with cursor #{cursor} "
    {docs, new_cursor} = SolrClient.full_update(demand, cursor)
    # TODO - we should be handling the end of the result set here
    Logger.info "new cursor is #{new_cursor}"
    {:noreply, docs, {:full, new_cursor}}
  end
  
  def handle_demand(demand, {:partial, cursor}) when demand > 0 do
    Logger.info "Receiving demand #{demand} with cursor #{cursor} "
    {docs, new_cursor} = SolrClient.partial_update(demand, cursor)
    # TODO - we should be handling the end of the result set here
    Logger.info "new cursor is #{new_cursor}"
    {:noreply, docs, {:partial, new_cursor}}
  end
end
