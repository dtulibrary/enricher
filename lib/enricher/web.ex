defmodule Enricher.Web do
  use Plug.Router

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  require Logger
  plug :match
  plug :dispatch

  post "/harvest/create" do
    case conn.params do
      %{"set" => "full", "endpoint" => solr_url} ->
        [code, msg] = process_harvest_request(:full, solr_url)
        send_resp(conn, code, msg) 
      %{"set" => "partial", "endpoint" => solr_url} ->
        [code, msg] = process_harvest_request(:partial, solr_url)
        send_resp(conn, code, msg) 
      _ ->
        send_resp(conn, 400, "Create requires arguments of set and endpoint")
    end  
  end

  defp process_harvest_request(harvest_type, endpoint) do
    case Enricher.HarvestManager.start_harvest(Manager, harvest_type, endpoint) do
      :ok -> [202, ""]
      :error -> [503, "Harvest already in progress"]
    end
  end

  post "/harvest/stop" do
    Enricher.HarvestManager.stop_harvest(Manager)
    send_resp(conn, 204, "")
  end

  get "/harvest/status" do
    status = Enricher.HarvestManager.status(Manager)
    status_code =
      case status.in_progress do
        true -> 202
        false -> 200
      end
    page = EEx.eval_file("templates/status.eex", [status: status])
    conn 
    |> put_resp_content_type("text/html")
    |> send_resp(status_code, page)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
