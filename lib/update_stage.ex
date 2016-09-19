alias Experimental.GenStage
defmodule UpdateStage do
  use GenStage
  require Logger

  def init(_args) do
    {:consumer, []}
  end

  def handle_events(updates, _from, []) do
    MetastoreUpdater.update_docs(updates)
    Enricher.HarvestManager.update_count(Manager, Enum.count(updates))
    {:noreply, [], []}
  end
  
  def handle_info({{prev, _sub}, :nomoredocs}, _state) do
    Logger.info "Received message :nomoredocs - committing and exiting..."
    MetastoreUpdater.commit_updates
    :timer.sleep(60000)
    GenStage.stop(prev, :nomoredocs)
    GenStage.stop(self, :nomoredocs)
  end

  def handle_info(_generic, state), do: {:noreply, [], state}
end
