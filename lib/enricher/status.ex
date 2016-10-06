defimpl Poison.Encoder, for: Enricher.Status do
  def encode(%{mode: mode, endpoint: endpoint, start_time: start_time, end_time: end_time, batch_size: batch_size, docs_processed: docs_processed, in_progress: in_progress}, options) do
    %{
      mode: mode,
      endpoint: endpoint,
      start_time: Enricher.Status.format_time(start_time),
      end_time: Enricher.Status.format_time(end_time),
      batch_size: batch_size,
      docs_processed: docs_processed,
      in_progress: in_progress
    } |> Poison.Encoder.encode([])
  end
end

defmodule Enricher.Status do
  defstruct [:endpoint, :mode, :start_time, :end_time, :reference, batch_size: 0, docs_processed: 0, in_progress: false]
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

  def format_time(nil), do: ""
  def format_time(datetime) do
    DateTime.to_iso8601(datetime)
  end

  defp calc_throughput(docs, time) when docs > 0 and time > 0 do
    (docs / time) |> Float.floor |> Kernel.trunc
  end
  defp calc_throughput(_,_), do: 0

  def search_endpoint(status) do
    status.endpoint <> "/solr/metastore/toshokan"
  end

  def update_endpoint(status) do
    status.endpoint <> "/solr/metastore/update"
  end
end
