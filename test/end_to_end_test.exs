defmodule EndToEndTest do
  use ExUnit.Case

  test "it finds all articles and places them on the stack" do
    {:ok, stack_pid} = Stack.start_link
    MetastoreMaster.add_articles_to_stack(stack_pid)
    assert %SolrDoc{} = Stack.pop(stack_pid)
  end
end
