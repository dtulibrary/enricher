defmodule StackTest do
  use ExUnit.Case

  test "push" do
    {:ok, stack} = Stack.start_link
    Stack.push(stack, 1)
    
    assert Stack.pop(stack) == 1
  end
end
