defmodule MetastoreUpdaterTest do
  use ExUnit.Case

  @update1 {"1937", ["dtu", "dtupub"]}
  @update2 {"1938", ["dtu"]}

  test "run" do
    {:ok, stack} = Stack.start_link
    Stack.push(stack, @update1)
    Stack.push(stack, @update2)
    MetastoreUpdater.run(stack)
  end

  test "create_updates" do
    updates = MetastoreUpdater.create_updates([@update1, @update2])
    assert is_list(updates)
  end

  test "create_update" do
     update = MetastoreUpdater.create_update(@update1)
     assert update == %{
       "id" => "1937",
       "fulltext_availability_ss" => %{"set" => ["dtu", "dtupub"]}
     }
  end
end
