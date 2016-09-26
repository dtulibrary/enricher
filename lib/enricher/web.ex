defmodule Enricher.Web do
  use Plug.Router

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
    message = Enricher.LogServer.last_message(WebLogger) 
    page = EEx.eval_file("templates/status.eex", [status: status, message: message])
    conn 
    |> put_resp_content_type("text/html")
    |> send_resp(status_code, page)
  end

  get "/harvest/log" do
    messages = Enricher.LogServer.messages(WebLogger)
    page = EEx.eval_file("templates/log.eex", [messages: messages])
    conn 
    |> put_resp_content_type("text/html")
    |> send_resp(200, page)
  end

  get "/debug/article" do
    page = case conn.params do
      %{"id" => id, "endpoint" => endpoint} ->
        article_debug_page(id, endpoint)
      %{} -> article_debug_form
    end
   conn
   |> put_resp_content_type("text/html")
   |> send_resp(200, page)
  end

  get "/cache/update" do
   page = EEx.eval_file("templates/update_cache.eex")
   conn
   |> put_resp_content_type("text/html")
   |> send_resp(200, page)
  end
  post "/cache/update" do
    endpoint = conn.params |> Map.get("endpoint")
    JournalCache.load_journals(Cache, endpoint)
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(201, "Cache updated") 
  end
    
  match _ do
    send_resp(conn, 404, "oops")
  end

  def article_debug_page(id, endpoint) do
    {article, journal, access} = Helpers.test_article(id, endpoint)
    EEx.eval_file("templates/debug_access.eex", [
      id: id, endpoint: endpoint, article: article, journal: journal, access: access
    ])
  end
  def article_debug_form do
    EEx.eval_file("templates/debug_form.eex") 
  end
end
