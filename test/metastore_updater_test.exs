defmodule MetastoreUpdaterTest do
  use ExUnit.Case

  @update1 {"1937", ["dtu", "dtupub"]}
  @update2 {"1938", ["dtu"]}

  test "run" do
    {:ok, queue} = Queue.start_link
    Queue.enqueue(queue, @update1)
    Queue.enqueue(queue, @update2)
    MetastoreUpdater.run(queue)
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
