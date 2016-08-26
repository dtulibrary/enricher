alias Experimental.GenStage
defmodule UpdateStage do
  use GenStage
  require Logger

  @buffer_size 1000000
  def init(:ok) do
    {:consumer, 0}
  end

  def handle_events(updates, _from, update_count) do
    Logger.info "handling update events"
    MetastoreUpdater.update_docs(updates)
    new_count = commit_buffer(updates, update_count)
    {:noreply, [], new_count}
  end
  
  def handle_info({{prev, _sub}, :nomoredocs}, _state) do
    Logger.info "Received message :nomoredocs - committing and exiting..."
    MetastoreUpdater.commit_updates
    :timer.sleep(60000)
    GenStage.stop(prev, :nomoredocs)
    GenStage.stop(self, :nomoredocs)
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 200}, :ok) do
    Logger.info "Commit succeeded"
    {:noreply, [], :ok}
  end

  def handle_info(_generic, :ok), do: {:noreply, [], :ok}

  @doc """
  Manage update buffer - if over buffer size - commit
  Return new buffer size
  """
  def commit_buffer(events, update_count) do
    count = Enum.count(events) + update_count 
    if count >= @buffer_size do
      Logger.info "Buffer is full - committing #{count} updates..."
      MetastoreUpdater.commit_updates
      0
    else count
    end
  end
end
