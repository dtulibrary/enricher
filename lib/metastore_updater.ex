defmodule MetastoreUpdater do
  require Logger
  @update_url Application.get_env(:enricher, :metastore_update, "http://localhost:8983/solr/update")

  def run(update_queue) do
    updates = Queue.batch(update_queue, 50)
    case updates do
      [] -> # no docs yet, wait a while
        Logger.debug "No docs on update queue, sleeping"
        :timer.sleep(1000)
        run(update_queue) 
      [:halt] -> # shutdown signal - no more updates
        Logger.info "Shutdown signal received - committing updates and shutting application down"
        commit_updates
        :init.stop()
        {:shutdown}
      updates ->
        Logger.debug "Updating docs"
        update_docs(updates)
        run(update_queue) # call recursively until no more updates
    end
  end

  def update_docs(updates) do
    updates |> create_updates |> send_updates
  end

  def send_updates(updates) when is_list(updates) do
    body = Poison.encode!(updates)
    headers = [{"Content-Type", "application/json"}]
    HTTPoison.post!(@update_url, body, headers) |> handle_response
  end

  def handle_response(%HTTPoison.Response{status_code: 400, body: body}) do
    msg = body |> Poison.decode! |> Map.get("error") |> Map.get("msg")
    Logger.error "Error updating: #{msg}"
  end

  def handle_response(%HTTPoison.Response{}), do: {:ok}

  def commit_updates do
    Logger.info "Committing updates"
    @update_url <> "?commit=true" |> HTTPoison.get!
  end

  def create_updates(elems) when is_list(elems) do
    Enum.map(elems, &create_update/1)
  end

  def create_update({doc_id, availability}) do
    %{
      "id" => doc_id,
      "fulltext_availability_ss" => %{"set" => availability}
    }
  end
end
