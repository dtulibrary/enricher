defmodule Enricher.Status do
  defstruct [:endpoint, :mode, :end_time, :reference, batch_size: 0, docs_processed: 0, start_time: DateTime.utc_now, in_progress: false]
  use ExConstructor

  def throughput(%Enricher.Status{in_progress: false, end_time: nil}), do: 0
  def throughput(%Enricher.Status{in_progress: true, end_time: nil, start_time: start_time, docs_processed: docs_processed}) do
    time_elapsed = DateTime.to_unix(DateTime.utc_now) - DateTime.to_unix(start_time) 
    calc_throughput(docs_processed, time_elapsed)
  end
  
  def throughput(%Enricher.Status{in_progress: false, start_time: start_time, end_time: end_time, docs_processed: docs_processed}) do
    time_elapsed = DateTime.to_unix(end_time) - DateTime.to_unix(start_time)
    calc_throughput(docs_processed, time_elapsed)
  end

  defp calc_throughput(docs, time) when docs > 0 and time > 0 do
    (docs / time) |> Float.floor |> Kernel.trunc
  end
  defp calc_throughput(_,_), do: 0
end

