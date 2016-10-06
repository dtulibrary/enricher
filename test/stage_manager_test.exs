defmodule Enricher.StageManagerTest do
  use ExUnit.Case, async: true

  defp startup_manager(context) do
    Enricher.StageManager.start_link(TestStageManager)
    context
  end

  describe "starting with name" do
    setup [:startup_manager]
    test "it starts with a name" do
      mpid = Process.whereis(TestStageManager)
      assert Process.alive?(mpid) 
    end
    test "it returns a state struct" do
      state = Enricher.StageManager.state(TestStageManager)
      assert state == Enricher.StageManager.State.new(%{})
    end
  end
  @tag :external
  describe "start_harvest" do
    setup [:startup_manager]
    test "it creates and tracks stages" do
      Enricher.StageManager.start_harvest(TestStageManager, :partial)
      state = Enricher.StageManager.state(TestStageManager)
      assert Enum.count(state.harvesters) == 1
      assert Enum.count(state.updaters) == 3
      assert Enum.count(state.deciders) == 3
    end
  end
end
