defmodule AccessDecider do
  def run(stack) do
    # 1. get doc from stack
    solr_doc = Stack.pop(stack)
    # 2. get holdings info for doc
    # 3. make access decision
  end

  def decide(%SolrDoc{}) do
    # 1. lookup journal
    # 2. check access
  end
end
