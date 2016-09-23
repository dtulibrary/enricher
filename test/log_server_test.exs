defmodule LogServerTest do
  use ExUnit.Case, async: true

  describe "log\2" do
    setup [:start_server]
    test "when there are no messages", %{server: pid} do
      Enricher.LogServer.log(pid, "bla bla")
      assert Enricher.LogServer.messages(pid) == ["bla bla"]
    end
    test "it does not store more than 50 messages", %{server: pid} do
      for i <- 1..100 do
        Enricher.LogServer.log(pid, "message#{i}")
      end
      assert length(Enricher.LogServer.messages(pid)) == 50
      assert Enricher.LogServer.last_message(pid) == "message100"
    end
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
