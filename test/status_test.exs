defmodule StatusTest do
  use ExUnit.Case, async: true
  describe "throughput\1" do
    test "when it is in progress it measures the docs processed since it started" do
      ten_minutes_ago = Map.merge(DateTime.utc_now, %{minute: DateTime.utc_now.minute - 10})
      status = Enricher.Status.new(in_progress: true, start_time: ten_minutes_ago, docs_processed: 1_000_000)
      assert Enricher.Status.throughput(status) == 1666
    end
    test "when it is complete it measures the docs processed in the time it ran" do
      ten_minutes_ago = Map.merge(DateTime.utc_now, %{minute: DateTime.utc_now.minute - 10})
      one_hour_ago = Map.merge(DateTime.utc_now, %{hour: DateTime.utc_now.hour - 1})
      status = Enricher.Status.new(in_progress: false, start_time: one_hour_ago, end_time: ten_minutes_ago, docs_processed: 60_000_000)
      assert Enricher.Status.throughput(status) == 20000
    end
    test "when it has not started yet" do
      status = Enricher.Status.new(%{})
      assert Enricher.Status.throughput(status) == 0
    end
  end
  describe "json" do
    test "it should be encoded as json" do
      ten_minutes_ago = Map.merge(DateTime.utc_now, %{minute: DateTime.utc_now.minute - 10})
      status = Enricher.Status.new(in_progress: true, start_time: ten_minutes_ago, docs_processed: 1_000_000)
      json = Poison.encode!(status)
      assert {:ok, _body} = Poison.decode(json)
    end
  end
end
