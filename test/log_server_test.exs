defmodule LogServerTest do
  use ExUnit.Case, async: true

  test "it starts up and can receive logs" do
    {:ok, pid} = Enricher.LogServer.start_link
    Enricher.LogServer.log(pid, "bla bla")
    assert Enricher.LogServer.messages(pid) == ["bla bla"]
  end
  describe "last message" do
    setup [:start_server]
    test "with no messages", %{server: pid} do
      assert Enricher.LogServer.last_message(pid) == nil
    end
    test "with one message", %{server: pid} do
      Enricher.LogServer.log(pid, "bla bla")
      assert Enricher.LogServer.last_message(pid) == "bla bla"
    end
    test "with several messages", %{server: pid} do
      Enricher.LogServer.log(pid, "bla bla")
      Enricher.LogServer.log(pid, "more bla")
      assert Enricher.LogServer.last_message(pid) == "more bla"
    end
  end
  describe "flush_log" do
    setup [:start_server]
    test "it empties the log", %{server: pid} do
      Enricher.LogServer.log(pid, "bla bla")
      Enricher.LogServer.log(pid, "more bla")
      Enricher.LogServer.flush_log(pid)
      assert Enricher.LogServer.messages(pid) == []
    end
  end
  defp start_server(context) do
    {:ok, pid} = Enricher.LogServer.start_link
    Map.merge(context, %{server: pid})
  end
end
