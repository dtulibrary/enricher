defmodule Enricher.HarvestMock do
  def start_harvest(_), do: :ok
  def start_harvest(_,_, _), do: :ok
  def stop_harvest(_), do: :ok
end
