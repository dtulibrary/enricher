defmodule StackTest do
  use ExUnit.Case

  setup do
    {:ok, stack} = Stack.start_link
    {:ok, stack: stack}
  end
  test "push", %{stack: stack} do
    Stack.push(stack, 1)

    assert Stack.pop(stack) == 1
  end

  test "batch_pop", %{stack: stack} do
    1..100 |> Enum.each(&Stack.push(stack, &1))

    batch = Stack.batch_pop(stack, 50)
    assert is_list(batch)
    assert 50 == Enum.count(batch)

    # should only give use entries with actual values - no nils
    new_batch = Stack.batch_pop(stack, 60)
    assert is_list(new_batch)
    assert 50 == Enum.count(new_batch)
    refute Enum.member?(new_batch, nil)
    
    # when the Stack is empty, gives an empty list
    assert 0 == Stack.batch_pop(stack, 50) |> Enum.count
  end
end
