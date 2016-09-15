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

  describe "/harvest/create" do
    test "returns client error code if not given valid parameter" do
      conn = conn(:post, "/harvest/create", %{"set" => "fudgemuffin"}) |> Enricher.Web.call(@opts)
      assert conn.state == :sent
      assert conn.status == 400
    end
    test "returns 200 if given valid parameters" do
      conn = conn(:post, "/harvest/create", %{"set" => "full", "endpoint" => "http://solr.test:8983"})
      conn = Enricher.Web.call(conn, @opts)
      assert conn.state == :sent
      assert conn.status == 201
    end
  end
  describe "status" do
    test "it can be retrieve the status from the HarvestManager" do
      conn = conn(:get, "/harvest/status") |> Enricher.Web.call(@opts)
      assert conn.state == :sent
      assert conn.status == 200
    end
  end
end
