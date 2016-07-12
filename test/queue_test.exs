defmodule QueueTest do
  use ExUnit.Case
  
  test "basic functionality" do
    {:ok, pid} = Queue.start_link([], name: :test_queue)
    Queue.enqueue(:test_queue, "val")
    assert Queue.dequeue(:test_queue) == "val"
    assert Queue.dequeue(:test_queue) == nil
  end

  test "batch" do
    {:ok, pid} = Queue.start_link([], name: :test_queue)
    1..100 |> Enum.each(&Queue.enqueue(:test_queue, &1))
    batch = Queue.batch(:test_queue, 50)
    assert is_list(batch)
    assert 50 == Enum.count(batch)

    new_batch = Queue.batch(:test_queue, 60)
    assert 50 == Enum.count(new_batch)
    refute Enum.member?(new_batch, nil)
  end

  test "batch with halt" do
    {:ok, pid} = Queue.start_link([], name: :test_queue)
    1..20 |> Enum.each(&Queue.enqueue(:test_queue, &1))
    Queue.enqueue(:test_queue, :halt)
    # Halt should not be included in a normal batch
    batch = Queue.batch(:test_queue, 50)
    refute Enum.member?(batch, :halt)
    # It should only come by itself
    new_batch = Queue.batch(:test_queue, 50)
    assert [:halt] == new_batch
  end 
end
