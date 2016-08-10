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
  
  def handle_info({{prev, _sub}, :nomoredocs}, _state) do
    Logger.info "Received message :nomoredocs"
    GenStage.stop(prev, :nomoredocs)
    GenStage.stop(self, :nomoredocs)
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 200}, :ok) do
    Logger.info "Commit succeeded"
    {:noreply, [], :ok}
  end
  def handle_info(_generic, :ok), do: {:noreply, [], :ok}
end
