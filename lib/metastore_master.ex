defmodule MetastoreMaster do
  def add_articles_to_stack(stack_pid) do
    SolrClient.stack_all_articles(stack_pid)
  end
end
