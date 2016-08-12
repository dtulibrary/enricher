alias Experimental.GenStage
defmodule DeciderStage do
  use GenStage
  require Logger

  def init(:ok) do
    Logger.info "Commencing Decider Stage - setting up ETS cache"
    {:ok, fetcher_pid} = GenServer.start_link(JournalFetcher, :journals)
    {:producer_consumer, fetcher_pid}
  end

  def handle_events(events, _from, fetcher) do
    :timer.sleep(1000)
    updates = Enum.map(events, &AccessDecider.create_update(&1, fetcher))
    {:noreply, updates, fetcher}
  end

  def handle_info({{producer, _sub}, :nomoredocs}, _state) do
    Logger.info "Received message nomoredocs"
    GenStage.async_notify(self(), :nomoredocs)
    GenStage.stop(producer, :nomoredocs)
    {:noreply, [], :ok}
  end
end
