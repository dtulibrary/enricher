defmodule Enricher do
  use Application
  require Logger
  # If there is no schedule configured, we'll use a yearly schedule to prevent it running
  # in our tests and development. i.e. this value should only be _real_ in production. 
  @full_run_schedule Application.get_env(:enricher, :full_run_schedule, "@yearly")
  @update_schedule Application.get_env(:enricher, :update_schedule, "@yearly")

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Queue, [[], [name: :doc_queue]], id: :doc_queue),
      worker(Queue, [[], [name: :update_queue]], id: :update_queue),
      worker(Task, [fn -> AccessDecider.process(:doc_queue, :update_queue) end], id: :decide, restart: :transient),
      worker(Task, [fn -> MetastoreUpdater.run(:update_queue) end], id: :update, restart: :transient)
    ]
    # Set up Solr fetch cron jobs

    Logger.info "Starting up harvesters with schedule #{@full_run_schedule}"
    full_run = %Quantum.Job{schedule: @full_run_schedule, task: fn -> MetastoreMaster.add_articles_to_stack(:doc_queue) end}
    Quantum.add_job(:full, full_run)
    # Run tasks
    opts = [strategy: :one_for_one]
    Logger.info "Starting up queues and processors"
    {:ok, _pid} = Supervisor.start_link(children, opts)
  end
end
