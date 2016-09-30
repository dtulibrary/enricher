defmodule CommitManagerTest do
  use ExUnit.Case, async: true
  alias Experimental.GenStage
  use GenStage

  setup do
    {:ok, manager} = CommitManager.start_link
    {:ok, manager: manager}
  end

  describe "update/2" do
    test "it changes the update count", %{manager: manager} do
      CommitManager.update(manager, 50)
      assert 50 == CommitManager.current_count(manager)
    end
    test "when the buffer is full it should commit and reset the count", %{manager: manager}   do
      CommitManager.update(manager, CommitManager.buffer_size)
      assert 0 == CommitManager.current_count(manager)
    end
  end
  describe "register_updater/2" do
    test "it allows us to register an updater", %{manager: manager} do
      {:ok, pid} = GenStage.start_link(UpdateStage, [])
      CommitManager.register_updater(manager, pid)
      assert CommitManager.updaters(manager) == [pid]
    end
  end
  describe "deregister_updater/2" do
    test "it disconnects an updater", %{manager: manager} do
      {:ok, pid} = GenStage.start_link(UpdateStage, [])
      CommitManager.register_updater(manager, pid)
      CommitManager.deregister_updater(manager, pid)
      assert CommitManager.updaters(manager) == []
    end
  end
end
