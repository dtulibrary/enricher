defmodule Enricher.Web do
  use Plug.Router

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  require Logger
  plug :match
  plug :dispatch

  post "/harvest/create" do
    case conn.params do
      %{"mode" => "full", "endpoint" => solr_url} ->
        [code, msg] = process_harvest_request(:full, solr_url)
        send_resp(conn, code, msg) 
      %{"mode" => "partial", "endpoint" => solr_url} ->
        [code, msg] = process_harvest_request(:partial, solr_url)
        send_resp(conn, code, msg) 
      %{"mode" => "sfx", "endpoint" => solr_url} ->
        [code, msg] = process_harvest_request(:sfx, solr_url)
        send_resp(conn, code, msg) 
      %{"mode" => "no_access", "endpoint" => solr_url} ->
        [code, msg] = process_harvest_request(:no_access, solr_url)
        send_resp(conn, code, msg) 
      _ ->
        send_resp(conn, 400, "Create requires arguments of mode and endpoint")
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

  get "/harvest/status.json" do
    status = Enricher.HarvestManager.status(Manager)
    json_status(conn, status)
  end

  get "/harvest/status" do
    status = Enricher.HarvestManager.status(Manager)
    cond do
      {"accept", "application/json"} in conn.req_headers ->
        json_status(conn, status)
      :else -> html_status(conn, status)
    end
  end

  defp html_status(conn, status) do
    resp_code = status_code(status)
    message = Enricher.LogServer.last_message(WebLogger) 
    page = EEx.eval_file("templates/status.eex", [status: status, message: message])
    conn |> put_resp_content_type("text/html") |> send_resp(resp_code, page)
  end

  defp json_status(conn, status) do
    resp_code = status_code(status)
    json = Poison.encode!(status)
    conn |> put_resp_content_type("application/json") |> send_resp(resp_code, json)
  end

  defp status_code(status) do 
    case status.in_progress do
      true -> 202
      false -> 200
    end
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
    {article, journal, access, update} = Helpers.test_article(id, endpoint)
    EEx.eval_file("templates/debug_access.eex", [
      id: id, endpoint: endpoint, article: article, journal: journal, access: access, update: update
    ])
  end
  def article_debug_form do
    EEx.eval_file("templates/debug_form.eex") 
  end
end
