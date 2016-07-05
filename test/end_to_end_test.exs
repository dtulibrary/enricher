defmodule EndToEndTest do
  use ExUnit.Case

  test "it finds all articles and places them on the stack" do
    {:ok, input_stack} = Stack.start_link
    {:ok, update_stack} = Stack.start_link
    MetastoreMaster.add_articles_to_stack(input_stack)
    AccessDecider.process(input_stack, update_stack)
    assert {id, access} = Stack.pop(update_stack)
    refute is_nil(id)
  end
end
