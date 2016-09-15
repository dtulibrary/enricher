alias Experimental.GenStage
defmodule DeciderStage do
  use GenStage
  require Logger

  def init(cache_pid) do
    Logger.info "Commencing Decider Stage"
    {:producer_consumer, cache_pid}
  end

  def handle_events(events, _from, cache_pid) do
    updates = Enum.map(events, &AccessDecider.create_update(&1, cache_pid))
    {:noreply, updates, cache_pid}
  end

  def handle_info({{_producer, _sub}, :nomoredocs}, _state) do
    Logger.info "Received message nomoredocs"
    GenStage.async_notify(self(), :nomoredocs)
    {:noreply, [], :ok}
  end
end
