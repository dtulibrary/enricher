defmodule CommitManagerTest do
  use ExUnit.Case
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
end
