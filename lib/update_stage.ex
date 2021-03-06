alias Experimental.GenStage
defmodule UpdateStage do
  use GenStage
  require Logger

  def init(_args) do
    {:consumer, []}
  end

  def handle_events(updates, _from, _) do
    MetastoreUpdater.update_docs(updates)
    count = Enum.count(updates)
    Enricher.HarvestManager.update_count(Manager, count)
    {:noreply, [], []}
  end
  
  def handle_info({{prev, _sub}, :nomoredocs}, _) do
    Logger.warn "Received message :nomoredocs - shutting down.."
    {:stop, :shutdown, :ok}
  end

  def handle_info(info, _), do: {:noreply, [], []}
end
