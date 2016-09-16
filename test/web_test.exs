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
    Enricher.HarvestManager.update_status(Manager, %{in_progress: true, docs_processed: 2_000})
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
    test "/create returns 503 is there is already a job running" do
      conn = conn(:post, "/harvest/create", %{"set" => "full", "endpoint" => "http://solr.test:8983"})
      conn = Enricher.Web.call(conn, @opts)
      assert conn.state == :sent
      assert conn.status == 503 
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
      conn = conn(:post, "/harvest/create", %{"set" => "full", "endpoint" => "http://solr.test:8983"})
      conn = Enricher.Web.call(conn, @opts)
      assert conn.state == :sent
      assert conn.status == 202
    end
    test "/create returns client error code if not given valid parameter" do
      conn = conn(:post, "/harvest/create", %{"set" => "fudgemuffin"}) |> Enricher.Web.call(@opts)
      assert conn.state == :sent
      assert conn.status == 400
    end
  end
  describe "/stop" do
    test "it stops the harvest" do
      conn = conn(:post, "/harvest/stop") |> Enricher.Web.call(@opts)
      assert conn.state == :sent
      assert conn.status == 204
    end
  end
end
