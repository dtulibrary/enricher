defmodule MetastoreMaster do
  def add_articles_to_stack(stack_pid) do
    # Make query
    # Start job to process queue

    ## {:ok, worker} = EnrichWorker.start_link

    # Populate queue
    SolrClient.stack_all_articles(stack_pid)
  end

  def process_documents(stack_pid) do

  end
end
