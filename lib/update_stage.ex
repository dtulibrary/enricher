alias Experimental.GenStage
defmodule UpdateStage do
  use GenStage
  require Logger

  def init(:ok) do
    {:consumer, :ok}
  end

  def handle_events(updates, _from, :ok) do
    Logger.info "handling update events"
    MetastoreUpdater.update_docs(updates)
    MetastoreUpdater.commit_updates
    {:noreply, [], :ok}
  end
end
