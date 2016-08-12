defmodule MetastoreUpdater do
  require Logger
  @update_url "#{Config.get(:enricher, :solr_url)}/solr/metastore/update"

  def update_docs(updates) do
    updates |> create_updates |> send_updates
  end

  def send_updates(updates) when is_list(updates) do
    body = Poison.encode!(updates)
    headers = [{"Content-Type", "application/json"}]
    Logger.info @update_url
    HTTPoison.post!(@update_url, body, headers, stream_to: self)# |> handle_response
  end

  def handle_response(%HTTPoison.Response{status_code: 400, body: body}) do
    msg = body |> Poison.decode! |> Map.get("error") |> Map.get("msg")
    Logger.error "Error updating: #{msg}"
  end

  def handle_response(%HTTPoison.Response{}), do: {:ok}

  @doc "Commit updates to Solr asynchronously"
  def commit_updates do
    Logger.info "Committing updates"
    @update_url <> "?commit=true" |> HTTPoison.get!([], stream_to: self)
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
