defmodule Dictionary do
  @moduledoc """
  This module is responsible for creating
  a dictionary of terms from Solr
  """
  require Logger
  def create_dictionary(endpoint) do
    import Supervisor.Spec
    children = [
      worker(QueueStash, []),
      worker(Queue, [DictionaryQueue])
    ]
    {:ok, spid} = Supervisor.start_link(children, strategy: :one_for_one)
    Task.async(fn -> harvest_solr_docs(endpoint) end)
  end

  def harvest_solr_docs(endpoint, nil) do
    Logger.info "Exiting"
  end
  def harvest_solr_docs(endpoint, cursor \\ "*") do
    {docs, new_cursor, batch_size} = SolrClient.full_update(100_000, cursor)
    docs |> Enum.each(fn(doc) -> Queue.add(DictionaryQueue, doc) end)
    harvest_solr_docs(endpoint, new_cursor)
  end
end

