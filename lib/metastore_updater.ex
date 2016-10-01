defmodule MetastoreUpdater do
  require Logger
  def update_url, do: Enricher.HarvestManager.update_endpoint(Manager)

  def update_docs(updates) do
    updates |> create_updates |> send_updates
  end

  def send_updates(updates) when is_list(updates) do
    body = Poison.encode!(updates)
    headers = [{"Content-Type", "application/json"}]
    Logger.debug "Sending updates to #{update_url}"
    HTTPoison.post(update_url, body, headers, stream_to: self)
  end

  @doc "Commit updates to Solr"
  def commit_updates do
    Logger.debug "Committing updates"
    update_url <> "?commit=true" |> HTTPoison.get!([], stream_to: self)
  end

  @doc """
  Commit updates to Solr 
  and open a new searcher - should only be
  called at conclusion of harvest.
  """
  def commit_updates(new_searcher: true) do
    Logger.debug "Committing updates and opening new searcher"
    update_url <> "?commit=true&openSearcher=true" |> HTTPoison.get!([], stream_to: self)
  end

  def create_updates(elems) when is_list(elems) do
    Enum.map(elems, &create_update/1)
  end

  def create_update(%MetastoreUpdate{id: doc_id, fulltext_access: access, fulltext_info: info}) do
    %{
      "id" => doc_id,
      "fulltext_availability_ss" => %{"set" => access},
      "fulltext_info_ss" => %{"set" => info}
    }
  end
end
