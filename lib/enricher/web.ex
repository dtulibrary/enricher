defmodule Enricher.Web do
  use Plug.Router

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  require Logger
  plug :match
  plug :dispatch
  @harvest_module Application.get_env(:enricher, :harvest_module, Enricher.HarvestManager)

  post "/harvest/create" do
    case conn.params do
      %{"set" => "full", "endpoint" => solr_url} ->
        @harvest_module.start_harvest(Manager, :full, solr_url)
        send_resp(conn, 202, "")
      %{"set" => "partial", "endpoint" => solr_url} ->
        @harvest_module.start_harvest(Manager, :partial, solr_url)
        send_resp(conn, 202, "")
      _ ->
        send_resp(conn, 400, "Create requires arguments of set and endpoint")
    end  
  end

  post "/harvest/stop" do
    @harvest_module.stop_harvest(Manager)
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
