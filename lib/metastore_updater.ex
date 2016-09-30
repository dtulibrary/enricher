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
    HTTPoison.post(update_url, body, headers, timeout: 120000, recvtimeout: 120000)
  end

  def handle_response(%HTTPoison.Response{status_code: 400, body: body}) do
    msg = body |> Poison.decode! |> Map.get("error") |> Map.get("msg")
    Logger.error "Error updating: #{msg}"
  end

  def handle_response(%HTTPoison.Response{status_code: code, body: body}) do
    Logger.debug "#{code} #{body}"
    {:ok}
  end

  @doc "Commit updates to Solr"
  def commit_updates do
    Logger.debug "Committing updates"
    update_url <> "?commit=true" |> HTTPoison.get!([], timeout: 120000, recvtimeout: 120000)
  end

  @doc """
  Commit updates to Solr 
  and open a new searcher - should only be
  called at conclusion of harvest.
  """
  def commit_updates(new_searcher: true) do
    Logger.debug "Committing updates and opening new searcher"
    update_url <> "?commit=true&openSearcher=true" |> HTTPoison.get!([], timeout: 120000, recvtimeout: 120000)
  end

  def create_updates(elems) when is_list(elems) do
    Enum.map(elems, &create_update/1)
  end

  def create_update(%MetastoreUpdate{id: doc_id, fulltext_access: access, fulltext_info: info}) do
    Logger.info "UPDATE: #{doc_id}: #{inspect access} - #{inspect info}"
    %{
      "id" => doc_id,
      "fulltext_availability_ss" => %{"set" => access},
      "fulltext_info_ss" => %{"set" => info}
    }
  end
end
