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
  def init(mode, subscribers \\ []) do
    Logger.info "Commencing full harvest"
    {:producer, {mode, @init_cursor, subscribers}}
  end

  def handle_demand(demand, state) when demand > 0 do
    process(demand, &SolrClient.full_update/2, state)
  end
  
  def handle_demand(demand, state) when demand > 0 do
    Logger.debug "Receiving demand #{demand}"
    process(demand, &SolrClient.partial_update/2, state)
  end

  def process(demand, harvest_function, {mode, cursor, subscribers}) do
    Logger.debug "Processing #{mode}.."
    {docs, new_cursor, batch_size} = harvest_function.(demand, cursor)
    Enricher.HarvestManager.update_batch_size(Manager, batch_size)
    if is_nil(new_cursor) do
      Logger.info "No more docs, messaging subscribers"
      Enricher.HarvestManager.harvest_complete(Manager)
      GenStage.async_notify(self(), :nomoredocs)
    end
    {:noreply, docs, {mode, new_cursor, subscribers}}
  end 
end
