alias Experimental.GenStage
defmodule UpdateStage do
  use GenStage
  require Logger

  def init(commit_manager) do
    {:consumer, commit_manager}
  end

  def handle_events(updates, _from, commit_manager) do
    Logger.info "handling update events"
    MetastoreUpdater.update_docs(updates)
    # Inform commit manager of number of updates 
    CommitManager.update(commit_manager, Enum.count(updates))
    {:noreply, [], commit_manager}
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
