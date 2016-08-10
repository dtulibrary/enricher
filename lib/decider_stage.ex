alias Experimental.GenStage
defmodule DeciderStage do
  use GenStage
  require Logger

  def init(:ok) do
    Logger.info "Commencing Decider Stage"
    {:producer_consumer, :nostate}
  end

  def handle_events(events, _from, state) do
    :timer.sleep(1000)
    Logger.debug "receiving #{Enum.count(events)} events with state #{state}"
    updates = Enum.map(events, &AccessDecider.create_update(&1))
    {:noreply, updates, state}
  end

  def handle_info({{producer, _sub}, :nomoredocs}, _state) do
    Logger.info "Received message nomoredocs"
    GenStage.async_notify(self(), :nomoredocs)
    GenStage.stop(producer, :nomoredocs)
    {:noreply, [], :ok}
  end
end
