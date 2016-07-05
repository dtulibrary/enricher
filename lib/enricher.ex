defmodule Enricher do
  def run do
    {:ok, input_stack} = Stack.start_link
    {:ok, update_stack} = Stack.start_link
    MetastoreMaster.add_articles_to_stack(input_stack)
    AccessDecider.process(input_stack, update_stack) 
  end
end
