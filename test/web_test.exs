defmodule WebTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts Enricher.Web.init([])
  describe "invalid requests" do
    test "returns 404" do
      conn = conn(:get, "/fail") |> Enricher.Web.call(@opts)
      assert conn.state == :sent
      assert conn.status == 404
    end
  end

  defp harvest_in_progress(_) do
    fake_task = Task.async(fn -> 1 + 1 end)
    Enricher.HarvestManager.update_status(Manager, %{in_progress: true, docs_processed: 2_000, reference: fake_task, start_time: DateTime.utc_now, edndpoint: "http://solr.test:8983"})
  end
  defp harvest_not_in_progress(_) do
    Enricher.HarvestManager.update_status(Manager, %{in_progress: false})
  end

  describe "when harvest is in progress" do
    setup [:harvest_in_progress]
    test "/status returns 202" do
      conn = conn(:get, "/harvest/status") |> Enricher.Web.call(@opts)
      assert conn.state == :sent
      assert conn.status == 202
    end
    test "/status can return json" do
      conn = conn(:get, "/harvest/status") |> put_req_header("accept", "application/json") |> Enricher.Web.call(@opts)

      assert conn.state == :sent
      assert conn.status == 202
      assert {"content-type", "application/json; charset=utf-8"} in conn.resp_headers 
      assert Poison.decode!(conn.resp_body)
    end
    test "/create returns 503 is there is already a job running" do
      conn = conn(:post, "/harvest/create", %{"mode" => "full", "endpoint" => "http://solr.test:8983"})
      conn = Enricher.Web.call(conn, @opts)
      assert conn.state == :sent
      assert conn.status == 503 
    end
    test "/stop stops the harvest" do
      conn = conn(:post, "/harvest/stop") |> Enricher.Web.call(@opts)
      assert conn.state == :sent
      assert conn.status == 204
    end
  end
  describe "when harvest is not in progress" do
    setup [:harvest_not_in_progress]
    test "/status it returns 200 when the harvest is not in progress" do
      conn = conn(:get, "/harvest/status") |> Enricher.Web.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
    end
    test "/create returns 202 if given valid parameters" do
      conn = conn(:post, "/harvest/create", %{"mode" => "full", "endpoint" => "http://solr.test:8983"})
      conn = Enricher.Web.call(conn, @opts)
      assert conn.state == :sent
      assert conn.status == 202
    end
    test "/create returns client error code if not given valid parameter" do
      conn = conn(:post, "/harvest/create", %{"mode" => "fudgemuffin"}) |> Enricher.Web.call(@opts)
      assert conn.state == :sent
      assert conn.status == 400
    end
  end
  describe "/debug/article" do
    test "it returns the access decision" do
      conn = conn(:get, "/debug/article", %{"id" => "123456789", "endpoint" => "http://solr.test:8983"}) |> Enricher.Web.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
    end
  end
end
