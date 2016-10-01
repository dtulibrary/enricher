alias Experimental.GenStage
defmodule UpdateStage do
  use GenStage
  require Logger

  def init(_args) do
    CommitManager.register_updater(CommitManager, self)
    {:consumer, []}
  end

  def handle_events(updates, _from, []) do
    MetastoreUpdater.update_docs(updates)
    count = Enum.count(updates)
    Enricher.HarvestManager.update_count(Manager, count)
    CommitManager.update(CommitManager, count)
    {:noreply, [], []}
  end
  
  def handle_info({{prev, _sub}, :nomoredocs}, state) do
    Logger.warn "Received message :nomoredocs - committing.."
    CommitManager.deregister_updater(CommitManager, self)
    {:noreply, [], state}
  end

  def handle_info(info, state) do
    Logger.debug "#{inspect info} received by UpdateStage"
    {:noreply, [], state}
  end
end
